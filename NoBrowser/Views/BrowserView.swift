import SwiftUI
import UIKit
import WebKit

struct BrowserView: View {
    let url: URL
    let onClose: () -> Void

    @StateObject private var model: WebViewModel
    @State private var puzzle = MathPuzzle.random()
    @State private var puzzleAnswer = ""
    @State private var showTryAgain = false

    init(url: URL, onClose: @escaping () -> Void) {
        self.url = url
        self.onClose = onClose
        _model = StateObject(wrappedValue: WebViewModel(url: url))
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                topBar

                ZStack(alignment: .top) {
                    WebViewRepresentable(url: url, model: model)

                    if model.isLoading {
                        ProgressView(value: model.estimatedProgress)
                            .progressViewStyle(.linear)
                            .tint(.blue)
                            .frame(height: 2)
                            .transition(.opacity)
                    }
                }
                .clipped()

                bottomToolbar
            }

            if let pending = model.pendingImage {
                puzzleOverlay(for: pending)
            }
        }
        .onChange(of: model.pendingImage) { _, newValue in
            if let newValue {
                puzzle = .random()
                puzzleAnswer = ""
                showTryAgain = false
                #if DEBUG
                debugAutoSolveIfRequested(for: newValue)
                #endif
            }
        }
    }

    // MARK: - Puzzle Overlay

    private func puzzleOverlay(for image: TappedImage) -> some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture { model.pendingImage = nil }

            VStack(spacing: 16) {
                Text("UNLOCK COLOUR")
                    .font(.custom("Times New Roman", size: 15).weight(.bold))
                    .kerning(2)
                    .foregroundColor(.white)

                Text("\(puzzle.question) = \(puzzleAnswer.isEmpty ? "?" : puzzleAnswer)")
                    .font(.custom("Times New Roman", size: 30))
                    .foregroundColor(.white)

                Text("Try again")
                    .font(.custom("Times New Roman", size: 13))
                    .foregroundColor(.red)
                    .opacity(showTryAgain ? 1 : 0)

                keypad

                HStack(spacing: 10) {
                    Button {
                        model.pendingImage = nil
                    } label: {
                        Text("Cancel")
                            .font(.custom("Times New Roman", size: 14))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 110, height: 44)
                            .background(Color(white: 0.18))
                    }
                    .buttonStyle(.plain)

                    Button {
                        submitAnswer(for: image)
                    } label: {
                        Text("Unlock")
                            .font(.custom("Times New Roman", size: 14).weight(.semibold))
                            .foregroundColor(.black)
                            .frame(width: 110, height: 44)
                            .background(Color.white)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
            .background(Color(white: 0.08))
        }
    }

    private var keypad: some View {
        VStack(spacing: 8) {
            ForEach([["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["C", "0", "⌫"]], id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { key in
                        keypadButton(key)
                    }
                }
            }
        }
    }

    private func keypadButton(_ key: String) -> some View {
        Button {
            showTryAgain = false
            switch key {
            case "C":
                puzzleAnswer = ""
            case "⌫":
                if !puzzleAnswer.isEmpty { puzzleAnswer.removeLast() }
            default:
                if puzzleAnswer.count < 3 { puzzleAnswer += key }
            }
        } label: {
            Text(key)
                .font(.custom("Times New Roman", size: 20).weight(.medium))
                .foregroundColor(.white)
                .frame(width: 74, height: 48)
                .background(Color(white: 0.18))
        }
        .buttonStyle(.plain)
    }

    private func submitAnswer(for image: TappedImage) {
        if !puzzleAnswer.isEmpty, Int(puzzleAnswer) == puzzle.answer {
            model.solvedSources.insert(image.src)
            model.pendingImage = nil
            model.webView?.revealPendingImage()
        } else {
            puzzleAnswer = ""
            puzzle = .random()
            showTryAgain = true
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: security.icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(security.color)

                if let label = security.label {
                    Text(label)
                        .font(.custom("Times New Roman", size: 12).weight(.semibold))
                        .foregroundColor(security.color)
                        .fixedSize()
                }

                Text(displayHost)
                    .font(.custom("Times New Roman", size: 13).weight(.medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .allowsHitTesting(false)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 30, height: 30)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
        .overlay(Divider(), alignment: .bottom)
    }

    /// Only the host is shown (never the path or query), so a URL like
    /// `evil.example/www.bank.com/login` can't pass for `www.bank.com`.
    /// URLs without a host (about:, data:, blob:) show just their scheme.
    private var displayHost: String {
        let u = model.currentURL
        if let host = u.host(percentEncoded: false), !host.isEmpty {
            return host
        }
        return "\(u.scheme ?? "unknown"):"
    }

    private struct SecurityIndicator {
        let icon: String
        let color: Color
        let label: String?
    }

    /// Green padlock only for https pages with no insecure subresources;
    /// plain http (or mixed content) is flagged "Not secure".
    private var security: SecurityIndicator {
        switch model.currentURL.scheme?.lowercased() {
        case "https" where model.hasOnlySecureContent:
            return SecurityIndicator(icon: "lock.fill", color: .green, label: nil)
        case "https", "http":
            return SecurityIndicator(icon: "lock.open.fill", color: .orange, label: "Not secure")
        default:
            return SecurityIndicator(icon: "info.circle", color: .secondary, label: nil)
        }
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        HStack(spacing: 0) {
            toolbarButton(icon: "chevron.left", enabled: model.canGoBack) {
                model.goBack()
            }
            toolbarButton(icon: "chevron.right", enabled: model.canGoForward) {
                model.goForward()
            }
            toolbarButton(icon: model.isLoading ? "xmark" : "arrow.clockwise", enabled: true) {
                model.reloadOrStop()
            }

            Button(action: shareCurrentURL) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 19))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }

            Button(action: onClose) {
                VStack(spacing: 3) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 19))
                    Text("Scan")
                        .font(.custom("Times New Roman", size: 9).weight(.semibold))
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .padding(.horizontal, 8)
        .background(Color(.systemBackground))
        .overlay(Divider(), alignment: .top)
    }

    @ViewBuilder
    private func toolbarButton(icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 19))
                .foregroundColor(enabled ? .blue : Color(.systemGray3))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .disabled(!enabled)
    }

    #if DEBUG
    /// DEBUG-only: with the `-NBDebugSolvePuzzle YES` launch argument, types
    /// the correct answer and submits it, for headless screenshots.
    private func debugAutoSolveIfRequested(for image: TappedImage) {
        guard UserDefaults.standard.bool(forKey: "NBDebugSolvePuzzle") else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            guard model.pendingImage == image else { return }
            puzzleAnswer = String(puzzle.answer)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                guard model.pendingImage == image else { return }
                submitAnswer(for: image)
            }
        }
    }
    #endif

    // MARK: - Math Puzzle

    struct MathPuzzle {
        let question: String
        let answer: Int

        static func random() -> MathPuzzle {
            let a = Int.random(in: 2...12)
            let b = Int.random(in: 2...9)
            switch Int.random(in: 0...2) {
            case 0:
                return MathPuzzle(question: "\(a) + \(b)", answer: a + b)
            case 1:
                return MathPuzzle(question: "\(a + b) − \(b)", answer: a)
            default:
                return MathPuzzle(question: "\(a) × \(b)", answer: a * b)
            }
        }
    }

    // MARK: - Share

    private func shareCurrentURL() {
        let shareURL = model.currentURL
        let av = UIActivityViewController(activityItems: [shareURL], applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        // iPad requires a popover anchor or UIActivityViewController crashes
        if let popover = av.popoverPresentationController {
            popover.sourceView = top.view
            popover.sourceRect = CGRect(
                x: top.view.bounds.midX,
                y: top.view.bounds.maxY - 40,
                width: 0, height: 0
            )
        }
        top.present(av, animated: true)
    }
}
