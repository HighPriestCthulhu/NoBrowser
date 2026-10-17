import SwiftUI

struct ContentView: View {
    @State private var scannedURLItem: URLItem?
    @State private var showingScanner = false
    @State private var pendingScanURL: URL?

    var body: some View {
        ScanGateView(showingScanner: $showingScanner) { url in
            scannedURLItem = URLItem(url: url)
        }
            .sheet(isPresented: $showingScanner, onDismiss: {
                if let url = pendingScanURL {
                    pendingScanURL = nil
                    scannedURLItem = URLItem(url: url)
                }
            }) {
                ScannerView(showingScanner: $showingScanner) { url in
                    pendingScanURL = url
                }
                .ignoresSafeArea()
            }
            .fullScreenCover(item: $scannedURLItem) { item in
                BrowserView(url: item.url) {
                    scannedURLItem = nil
                }
            }
            .onOpenURL { url in
                guard url.scheme == "http" || url.scheme == "https" else { return }
                showingScanner = false
                scannedURLItem = URLItem(url: url)
            }
            #if DEBUG
            .onAppear {
                // DEBUG-only: `-NBDebugOpenURL <http(s) URL>` opens a page at
                // launch. On iOS, `simctl openurl http://…` goes to the default
                // browser (Safari), not to this app, so screenshots need this.
                if let string = UserDefaults.standard.string(forKey: "NBDebugOpenURL"),
                   let url = URL(string: string),
                   url.scheme == "http" || url.scheme == "https" {
                    scannedURLItem = URLItem(url: url)
                }
            }
            #endif
    }
}
