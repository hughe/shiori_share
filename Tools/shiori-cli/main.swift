// shiori-cli: exercise the Shiori Share API client (Shared/ShioriClient.swift)
// against a real Shiori server, without the app or share extension.
//
// Build:  make cli            -> build/shiori-cli
// Run:    build/shiori-cli --server https://shiori-emberson-test.fly.dev --user hugh probe
//
// Compiled from Shared/ShioriClient.swift, Shared/String+URL.swift and
// Shared/TrustSelfSignedCertificatesDelegate.swift plus this file, so it uses
// exactly the same request/response code as the app.

import Foundation

let usage = """
usage: shiori-cli [options] <command> [args]

commands:
  login                 log in and show what the server returned
  tags                  list tags with bookmark counts
  add <url>             add a bookmark (writes to the server)
                          --title <t>  --excerpt <e>  --tags a,b,c  --archive  --public
  probe                 log in, then fetch tags once per auth style and report
                        which ones the server accepts (read-only)

options:
  --server <url>        Shiori base URL (default: $SHIORI_URL)
  --user <name>         username (default: $SHIORI_USER)
                        password comes from $SHIORI_PASSWORD, otherwise it is prompted for
  --auth <style>        bearer | session-id, used by tags/add (default: bearer)
  --insecure            trust a self-signed certificate for the server's host
  -v, --verbose         log each request and response
  -h, --help            show this help
"""

// MARK: - Output helpers

func printErr(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
}

func fail(_ message: String, code: Int32 = 2) -> Never {
    printErr("shiori-cli: \(message)")
    exit(code)
}

func redact(_ secret: String) -> String {
    let prefix = secret.prefix(6)
    return "\(prefix)… (\(secret.count) chars)"
}

func describe(_ error: Error) -> String {
    guard let apiError = error as? ShioriAPIError else { return "\(error)" }
    var text = apiError.errorDescription ?? "\(apiError)"
    switch apiError {
    case .decodingError(let underlying), .connectionFailed(let underlying), .unknownError(let underlying):
        text += "\n    underlying: \(underlying)"
    default:
        break
    }
    return text
}

// MARK: - Arguments

let valueOptions: Set<String> = ["--server", "--user", "--auth", "--title", "--excerpt", "--tags"]
let flagOptions: Set<String> = ["--insecure", "--archive", "--public", "--verbose", "-v", "--help", "-h"]

var options: [String: String] = [:]
var flags = Set<String>()
var positional: [String] = []

let arguments = Array(CommandLine.arguments.dropFirst())
var index = 0
while index < arguments.count {
    let argument = arguments[index]
    if valueOptions.contains(argument) {
        guard index + 1 < arguments.count else { fail("\(argument) needs a value") }
        options[argument] = arguments[index + 1]
        index += 2
    } else if flagOptions.contains(argument) {
        flags.insert(argument)
        index += 1
    } else if argument.hasPrefix("-") {
        fail("unknown option \(argument)\n\n\(usage)")
    } else {
        positional.append(argument)
        index += 1
    }
}

if flags.contains("--help") || flags.contains("-h") || positional.isEmpty {
    print(usage)
    exit(positional.isEmpty && !(flags.contains("--help") || flags.contains("-h")) ? 2 : 0)
}

let environment = ProcessInfo.processInfo.environment
let command = positional[0]

guard let rawServer = options["--server"] ?? environment["SHIORI_URL"], !rawServer.isEmpty else {
    fail("no server: pass --server or set SHIORI_URL")
}
// Same normalisation the app applies to the server URL setting.
let serverString = rawServer.normalizedServerURL
guard serverString.isValidHTTPURL, let baseURL = URL(string: serverString) else {
    fail("invalid server URL: \(rawServer)")
}

guard let username = options["--user"] ?? environment["SHIORI_USER"], !username.isEmpty else {
    fail("no username: pass --user or set SHIORI_USER")
}

let authName = options["--auth"] ?? "bearer"
guard let authStyle = ShioriAuthStyle(rawValue: authName) else {
    fail("--auth must be one of: \(ShioriAuthStyle.allCases.map(\.rawValue).joined(separator: ", "))")
}

func readPassword() -> String {
    if let password = environment["SHIORI_PASSWORD"], !password.isEmpty {
        return password
    }
    var buffer = [CChar](repeating: 0, count: 1024)
    let entered = buffer.withUnsafeMutableBufferPointer { pointer -> String? in
        guard let base = pointer.baseAddress,
              readpassphrase("Password for \(username): ", base, pointer.count, 0) != nil else {
            return nil
        }
        return String(cString: base)
    }
    if let entered = entered {
        return entered
    }
    fail("could not read password")
}

// MARK: - Client

var client = ShioriClient(
    baseURL: baseURL,
    authStyle: authStyle,
    trustSelfSignedCerts: flags.contains("--insecure")
)
if flags.contains("--verbose") || flags.contains("-v") {
    client.onRequest = { method, url in
        printErr("-> \(method) \(url.absoluteString)")
    }
    client.onResponse = { method, url, statusCode, duration in
        printErr("<- \(statusCode) \(method) \(url.absoluteString) (\(Int(duration * 1000))ms)")
    }
}

func printCredential(_ credential: ShioriCredential) {
    print("login OK (\(baseURL.absoluteString) as \(username))")
    print("  token:   \(redact(credential.token))")
    print("  session: \(credential.session.map(redact) ?? "(none returned)")")
    if let expires = credential.expires {
        print("  expires: \(expires) (\(Date(timeIntervalSince1970: TimeInterval(expires))) if Unix seconds)")
    } else {
        print("  expires: (none returned)")
    }
}

// MARK: - Commands

do {
    switch command {
    case "login":
        let credential = try await client.login(username: username, password: readPassword())
        printCredential(credential)

    case "tags":
        let credential = try await client.login(username: username, password: readPassword())
        let tags = try await client.fetchTags(auth: credential.value(for: authStyle))
        for tag in tags.sorted(by: { $0.bookmarkCount > $1.bookmarkCount }) {
            print("\(tag.bookmarkCount)\t\(tag.name)")
        }
        printErr("\(tags.count) tags (auth: \(authStyle.rawValue))")

    case "add":
        guard positional.count == 2 else { fail("usage: shiori-cli add <url> [--title ...]") }
        let url = positional[1]
        guard url.isValidHTTPURL else { fail("not an http(s) URL: \(url)") }

        let credential = try await client.login(username: username, password: readPassword())
        let bookmark = BookmarkRequest(
            url: url,
            title: options["--title"],
            excerpt: options["--excerpt"],
            tags: ShioriClient.parseKeywords(options["--tags"]),
            createArchive: flags.contains("--archive"),
            public: flags.contains("--public") ? 1 : 0
        )
        let response = try await client.addBookmark(bookmark, auth: credential.value(for: authStyle))
        print("added bookmark id=\(response.id) \(response.url) \(response.title ?? "")")
        printErr("(auth: \(authStyle.rawValue); delete it in the web UI when done testing)")

    case "probe":
        let credential = try await client.login(username: username, password: readPassword())
        printCredential(credential)
        print("GET \(ShioriClient.Path.tags) by auth style:")

        var accepted: [ShioriAuthStyle] = []
        for style in ShioriAuthStyle.allCases {
            var probeClient = client
            probeClient.authStyle = style
            let note = (style == .sessionID && credential.session == nil) ? " (no session returned; sending token)" : ""
            do {
                let tags = try await probeClient.fetchTags(auth: credential.value(for: style))
                print("  \(style.rawValue): accepted, \(tags.count) tags\(note)")
                accepted.append(style)
            } catch {
                print("  \(style.rawValue): FAILED\(note): \(describe(error))")
            }
        }

        if accepted.contains(.bearer) {
            print("Bearer works: the Bearer build of Shiori Share should work against this server.")
        } else {
            print("Bearer rejected: do not switch the app to Bearer against this server yet.")
        }
        exit(accepted.isEmpty ? 1 : 0)

    default:
        fail("unknown command \(command)\n\n\(usage)")
    }
} catch {
    fail(describe(error), code: 1)
}
