import SwiftUI
import AVKit
import AVFoundation

struct CapsuleDetailView: View {
    let capsule: TimeCapsule
    @ObservedObject var manager: TimeCapsuleManager
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(alignment: .leading) {
            Text(capsule.title)
                .font(.largeTitle)
            
            Text("Unlock Date: \(capsule.unlockDate, formatter: dateFormatter)")
                .foregroundColor(.secondary)
            
            Divider()
            
            if capsule.mediaType == .message {
                Text(capsule.message ?? "No message available.")
                    .multilineTextAlignment(.leading)
                    .padding()
                    .font(.body)
            } else if let mediaURL = capsule.mediaURL {
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: mediaURL.path) {
                    Text("File exists at path: \(mediaURL.path)")
                } else {
                    Text("File does not exist at path: \(mediaURL.path)")
                }

                switch capsule.mediaType {
                case .image:
                    AsyncImage(url: mediaURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: 300)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: 300)
                        case .failure:
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, maxHeight: 300)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    
                case .video:
                    Text("Video URL: \(mediaURL)")
                    VideoPlayer(player: AVPlayer(url: mediaURL))
                        .frame(maxWidth: .infinity)
                        .aspectRatio(16/9, contentMode: .fit)
                    
                case .audio:
                    
                    Text("Audio URL: \(mediaURL)")
                    AudioPlayerView(audioURL: mediaURL)
                default:
                    Text("Unsupported media type.")
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Capsule Details")
        .navigationBarItems(trailing: deleteButton)
    }

    private var deleteButton: some View {
        if capsule.unlockDate <= Date() {
            return AnyView(Button(action: deleteCapsule) {
                Text("Delete")
                    .font(.subheadline)
                    .foregroundColor(.red)
            })
        } else {
            return AnyView(EmptyView())
        }
    }

    private func deleteCapsule() {
        manager.deleteCapsule(withID: capsule.id)
        presentationMode.wrappedValue.dismiss()
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

