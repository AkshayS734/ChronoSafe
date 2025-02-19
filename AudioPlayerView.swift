import AVKit
import SwiftUI

struct AudioPlayerView: View {
    let audioURL: URL
    @State private var player: AVPlayer?

    var body: some View {
        VStack {
            if let player = player {
                VideoPlayer(player: player)
                    .frame(height: 50)
                    .onAppear {
                        player.play()
                    }
            } else {
                Button("Play Audio") {
                    player = AVPlayer(url: audioURL)
                    player?.play()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }
}
