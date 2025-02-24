import SwiftUI
import AVFoundation

@MainActor
class AudioPlayerViewModel: ObservableObject {
    @Published var isPlaying = false
    private var audioPlayer: AVAudioPlayer?
    var audioURL: URL

    init(audioURL: URL) {
        self.audioURL = audioURL
//        setupAudioSession()
//        loadAudio()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            print("Audio session activated for playback")
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }

    private func loadAudio() {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: audioURL.path) {
            do {
                print("🎵 Attempting to load audio from: \(audioURL.path)")
                audioPlayer = try AVAudioPlayer(contentsOf: audioURL.standardizedFileURL)
                audioPlayer?.prepareToPlay()
                print("Audio successfully loaded")
            } catch {
                print("Failed to load audio: \(error.localizedDescription)")
            }
        } else {
            print("Audio file does not exist yet: \(audioURL.path)")
        }
    }

    func playOrPause() {
        if audioPlayer == nil {
            loadAudio()
        }

        guard let player = audioPlayer else {
            print("Audio player is still nil after attempting to load")
            return
        }

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
                    .frame(width: 40, height: 40)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .onAppear {
            print("Audio file path: \(audioPlayerViewModel.audioURL.path)")
        }
    }
}
