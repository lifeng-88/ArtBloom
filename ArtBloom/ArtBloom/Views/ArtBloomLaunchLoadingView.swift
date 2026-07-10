import SwiftUI

struct ArtBloomLaunchLoadingView: View {
    var body: some View {
        ZStack {
            MSColor.roseMist.ignoresSafeArea()
            VStack(spacing: 20) {
                Image("LaunchIllustration")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                ProgressView()
                    .tint(MSColor.primary)
                    .scaleEffect(1.1)
            }
        }
    }
}
