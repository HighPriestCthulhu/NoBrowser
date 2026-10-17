import SwiftUI

struct ScanGateView: View {
    @Binding var showingScanner: Bool
    /// Called when one of the built-in site buttons is tapped.
    var onOpenSite: ((URL) -> Void)? = nil

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 80, weight: .thin))
                    .foregroundColor(.white)
                    .padding(.bottom, 32)

                Text("SCAN QR CODE")
                    .font(.custom("Times New Roman", size: 18).weight(.bold))
                    .kerning(3)
                    .foregroundColor(.white)

                Text("Point your camera at any QR code")
                    .font(.custom("Times New Roman", size: 13))
                    .foregroundColor(Color.white.opacity(0.35))
                    .padding(.top, 10)

                Button {
                    showingScanner = true
                } label: {
                    Text("SCAN QR CODE")
                        .font(.custom("Times New Roman", size: 15).weight(.semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .padding(.top, 44)

                VStack(spacing: 12) {
                    curatedSiteButton("Wikipedia", "https://www.wikipedia.org")
                    curatedSiteButton("Wolfram", "https://www.wolframalpha.com")
                    curatedSiteButton("Stanford Philosophy", "https://plato.stanford.edu")
                }
                .padding(.top, 20)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func curatedSiteButton(_ title: String, _ urlString: String) -> some View {
        Button {
            onOpenSite?(URL(string: urlString)!)
        } label: {
            Text(title)
                .font(.custom("Times New Roman", size: 12).weight(.medium))
                .foregroundColor(.white)
                .frame(width: 140)
                .padding(.vertical, 8)
                .background(Color(white: 0.18))
        }
        .buttonStyle(.plain)
    }
}
