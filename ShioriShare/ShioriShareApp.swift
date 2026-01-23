import SwiftUI
#if os(macOS)
import AppKit
#endif

@main
struct ShioriShareApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        Settings {
            SettingsView()
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .toolbar) { }
            CommandGroup(replacing: .appInfo) {
                Button("About Shiori Share") {
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.alignment = .center
                    
                    let credits = NSMutableAttributedString(
                        string: "Shiori is a simple, self-hosted, bookmark manager built with Go.\n\n",
                        attributes: [
                            .font: NSFont.systemFont(ofSize: 11),
                            .paragraphStyle: paragraphStyle
                        ]
                    )
                    
                    let urlString = "https://github.com/go-shiori/shiori"
                    let link = NSAttributedString(
                        string: urlString,
                        attributes: [
                            .font: NSFont.systemFont(ofSize: 11),
                            .paragraphStyle: paragraphStyle,
                            .link: URL(string: urlString)!
                        ]
                    )
                    credits.append(link)
                    
                    NSApplication.shared.orderFrontStandardAboutPanel(options: [
                        .applicationName: "Shiori Share",
                        .credits: credits
                    ])
                }
            }
        }
        #endif
    }
}

#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.async {
            for window in NSApplication.shared.windows {
                window.collectionBehavior.remove(.fullScreenPrimary)
                window.collectionBehavior.insert(.fullScreenNone)
            }
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
#endif
