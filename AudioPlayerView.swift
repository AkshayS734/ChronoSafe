import SwiftUI
import AVFoundation

@MainActor
class AudioPlayerViewModel: ObservableObject {
    @Published var isPlaying = false
    private var audioPlayer: AVAudioPlayer?

    init(audioURL: URL) {
        do {
            #if targetEnvironment(simulator)
            print("🎵 Running in Simulator - AVAudioSession won't work, but playback should.")
            #endif
            self.audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            self.audioPlayer?.prepareToPlay()
        } catch {
            print("🚨 Failed to load audio: \(error.localizedDescription)")
        }
    }

    func playOrPause() {
        guard let player = audioPlayer else { return }

        if player.isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }
}

struct AudioPlayerView: View {
    @StateObject private var audioPlayerViewModel: AudioPlayerViewModel

    init(audioURL: URL) {
        _audioPlayerViewModel = StateObject(wrappedValue: AudioPlayerViewModel(audioURL: audioURL))
    }

    var body: some View {
        VStack {
            Button(action: {
                audioPlayerViewModel.playOrPause()
            }) {
                Image(systemName: audioPlayerViewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
}
