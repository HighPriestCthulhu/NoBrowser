import SwiftUI
import Vision
import VisionKit

struct ScannerView: View {
    @Binding var showingScanner: Bool
    var onURLScanned: (URL) -> Void

    var body: some View {
        ZStack {
            if DataScannerViewController.isSupported {
                DataScannerRepresentable { url in
                    showingScanner = false
                    onURLScanned(url)
                }
                .ignoresSafeArea()

                ViewfinderOverlay()
            } else {
                Color.black.ignoresSafeArea()
                VStack(spacing: 16) {
                    Image(systemName: "camera.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.6))
                    Text("QR scanning is not supported on this device.")
                        .font(.custom("Times New Roman", size: 15))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }

            VStack {
                Spacer()
                Button("Cancel") {
                    showingScanner = false
                }
                .font(.custom("Times New Roman", size: 16).weight(.medium))
                .foregroundColor(.white.opacity(0.8))
                .padding(.bottom, 52)
            }
        }
        .background(Color.black)
    }
}

// MARK: - UIViewControllerRepresentable

struct DataScannerRepresentable: UIViewControllerRepresentable {
    var onURLScanned: (URL) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .balanced,
            isHighlightingEnabled: false
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if !uiViewController.isScanning {
            try? uiViewController.startScanning()
        }
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onURLScanned: onURLScanned)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let onURLScanned: (URL) -> Void
        private var hasScanned = false

        init(onURLScanned: @escaping (URL) -> Void) {
            self.onURLScanned = onURLScanned
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            guard !hasScanned else { return }

            for item in addedItems {
                if case .barcode(let barcode) = item,
                   let payload = barcode.payloadStringValue,
                   let url = URL(string: payload),
                   url.scheme == "http" || url.scheme == "https" {
                    hasScanned = true
                    dataScanner.stopScanning()
                    DispatchQueue.main.async {
                        self.onURLScanned(url)
                    }
                    return
                }
            }
        }
    }
}

// MARK: - Viewfinder Overlay

struct ViewfinderOverlay: View {
    private let boxSize: CGFloat = 230
    private let cornerLen: CGFloat = 32
    private let strokeWidth: CGFloat = 3.5

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let cx = size.width / 2
            let cy = size.height / 2
            let half = boxSize / 2
            let boxRect = CGRect(x: cx - half, y: cy - half, width: boxSize, height: boxSize)
            let r: CGFloat = 14

            ZStack {
                // Dark overlay with transparent cutout via even-odd fill
                Path { path in
                    path.addRect(CGRect(origin: .zero, size: size))
                    path.addRoundedRect(
                        in: boxRect,
                        cornerSize: CGSize(width: r, height: r)
                    )
                }
                .fill(.black.opacity(0.55), style: FillStyle(eoFill: true))

                // Corner bracket strokes
                Path { path in
                    let minX = boxRect.minX
                    let maxX = boxRect.maxX
                    let minY = boxRect.minY
                    let maxY = boxRect.maxY

                    // Top-left
                    path.move(to: CGPoint(x: minX + cornerLen, y: minY))
                    path.addLine(to: CGPoint(x: minX + r, y: minY))
                    path.addQuadCurve(to: CGPoint(x: minX, y: minY + r),
                                      control: CGPoint(x: minX, y: minY))
                    path.addLine(to: CGPoint(x: minX, y: minY + cornerLen))

                    // Top-right
                    path.move(to: CGPoint(x: maxX - cornerLen, y: minY))
                    path.addLine(to: CGPoint(x: maxX - r, y: minY))
                    path.addQuadCurve(to: CGPoint(x: maxX, y: minY + r),
                                      control: CGPoint(x: maxX, y: minY))
                    path.addLine(to: CGPoint(x: maxX, y: minY + cornerLen))

                    // Bottom-left
                    path.move(to: CGPoint(x: minX + cornerLen, y: maxY))
                    path.addLine(to: CGPoint(x: minX + r, y: maxY))
                    path.addQuadCurve(to: CGPoint(x: minX, y: maxY - r),
                                      control: CGPoint(x: minX, y: maxY))
                    path.addLine(to: CGPoint(x: minX, y: maxY - cornerLen))

                    // Bottom-right
                    path.move(to: CGPoint(x: maxX - cornerLen, y: maxY))
                    path.addLine(to: CGPoint(x: maxX - r, y: maxY))
                    path.addQuadCurve(to: CGPoint(x: maxX, y: maxY - r),
                                      control: CGPoint(x: maxX, y: maxY))
                    path.addLine(to: CGPoint(x: maxX, y: maxY - cornerLen))
                }
                .stroke(.white, lineWidth: strokeWidth)

                // Caption below viewfinder
                VStack {
                    Spacer().frame(height: cy + half + 20)
                    Text("Align QR code in frame")
                        .font(.custom("Times New Roman", size: 13))
                        .foregroundColor(.white.opacity(0.65))
                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
    }
}
