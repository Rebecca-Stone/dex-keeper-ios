import SwiftUI

/// Async sprite loader with a clean placeholder and a soft gradient backdrop.
struct SpriteImage: View {
    let url: URL?
    var size: CGFloat = 56
    var tint: Color = .gray

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .interpolation(.none)   // crisp pixel sprites
                    .scaledToFit()
            case .failure:
                Image(systemName: "questionmark.circle")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
                    .padding(size * 0.2)
            default:
                ProgressView()
            }
        }
        .frame(width: size, height: size)
        .background(
            Circle().fill(tint.opacity(0.12))
        )
    }
}
