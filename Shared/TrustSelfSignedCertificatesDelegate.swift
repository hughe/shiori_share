import Foundation

final class TrustSelfSignedCertificatesDelegate: NSObject, URLSessionDelegate {
    private let allowedHost: String?
    
    init(allowedHost: String? = nil) {
        self.allowedHost = allowedHost
    }
    
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        if let allowedHost = allowedHost,
           challenge.protectionSpace.host != allowedHost {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        completionHandler(.useCredential, URLCredential(trust: trust))
    }
}
