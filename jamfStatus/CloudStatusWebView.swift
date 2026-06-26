import SwiftUI
import WebKit

struct CloudStatusWebView: View {
    let url: URL
    @StateObject private var nav = WebNavState()

    var body: some View {
        WebViewRepresentable(url: url, nav: nav)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: { nav.webView?.goBack() }) {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(!nav.canGoBack)
                }
                ToolbarItem(placement: .navigation) {
                    Button(action: { nav.webView?.goForward() }) {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(!nav.canGoForward)
                }
            }
    }
}

// MARK: - Navigation state

@MainActor
final class WebNavState: ObservableObject {
    @Published var canGoBack    = false
    @Published var canGoForward = false
    weak var webView: WKWebView?
}

// MARK: - NSViewRepresentable

private struct WebViewRepresentable: NSViewRepresentable {
    let url: URL
    let nav: WebNavState

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate         = context.coordinator
        nav.webView = webView
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(nav: nav) }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let nav: WebNavState

        init(nav: WebNavState) { self.nav = nav }

        // Allow all navigation actions
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }

        // Handle target="_blank" links — load in the same webview
        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task { @MainActor in
                nav.canGoBack    = webView.canGoBack
                nav.canGoForward = webView.canGoForward
            }
        }

        func webView(_ webView: WKWebView,
                     didReceive challenge: URLAuthenticationChallenge,
                     completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            if let trust = challenge.protectionSpace.serverTrust {
                completionHandler(.useCredential, URLCredential(trust: trust))
            } else {
                completionHandler(.performDefaultHandling, nil)
            }
        }
    }
}
