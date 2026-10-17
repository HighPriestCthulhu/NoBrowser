import Foundation
import Combine
import WebKit

struct TappedImage: Identifiable, Equatable {
    let id = UUID()
    // Raw src string exactly as the page's JS reports it — used verbatim
    // as the solvedSources key so both sides always agree.
    let src: String
}

final class WebViewModel: ObservableObject {
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = false
    @Published var estimatedProgress: Double = 0
    @Published var currentURL: URL
    @Published var hasOnlySecureContent = false

    // Colour-unlock state: puzzle pending for a tapped image.
    // solvedSources skips the puzzle for images already unlocked
    // on this page (cleared on navigation).
    @Published var pendingImage: TappedImage?
    var solvedSources = Set<String>()

    weak var webView: WKWebView?

    init(url: URL) {
        currentURL = url
    }

    func goBack() {
        webView?.goBack()
    }

    func goForward() {
        webView?.goForward()
    }

    func reloadOrStop() {
        if isLoading {
            webView?.stopLoading()
        } else {
            webView?.reload()
        }
    }

    func sync(from webView: WKWebView) {
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        isLoading = webView.isLoading
        estimatedProgress = webView.estimatedProgress
        hasOnlySecureContent = webView.hasOnlySecureContent
        if let url = webView.url {
            currentURL = url
        }
    }

    #if DEBUG
    // MARK: - DEBUG-only screenshot helpers
    //
    // Launch arguments (DEBUG builds only; see README "Debug launch arguments"):
    //   -NBDebugTapImage <n>    after the first page finishes loading, simulate a
    //                           tap on the nth <img> (0-based), opening the puzzle.
    //   -NBDebugSolvePuzzle YES when the puzzle appears, enter the correct answer
    //                           and submit it after a short pause.

    private var debugDidTap = false

    func debugPageDidFinish() {
        guard !debugDidTap,
              UserDefaults.standard.object(forKey: "NBDebugTapImage") != nil else { return }
        debugDidTap = true
        let index = UserDefaults.standard.integer(forKey: "NBDebugTapImage")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            // Dispatches a real click event, so this goes through the same
            // injected listener and message handler as a finger tap.
            self?.webView?.evaluateJavaScript(
                "document.images[\(index)] && document.images[\(index)].click()",
                in: nil,
                in: WebViewRepresentable.contentWorld
            )
        }
    }
    #endif
}
