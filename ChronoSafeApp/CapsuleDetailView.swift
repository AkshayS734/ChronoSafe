import SwiftUI
import AVKit
import AVFoundation

struct CapsuleDetailView: View {
    let capsule: TimeCapsule
    @ObservedObject var manager: TimeCapsuleManager
    @Environment(\.presentationMode) var presentationMode
    @State private var isAuthenticated = false
    @State private var showingAuthenticationAlert = false

    var body: some View {
        Group {
            if capsule.unlockDate <= Date() {
                if isAuthenticated {
                    capsuleContent
                } else {
                    authenticatePrompt
                }
            } else {
                lockedContent
            }
        }
        .onAppear {
            if capsule.unlockDate <= Date() {
                authenticateUser()
            }
        }
        .alert("Authentication Failed", isPresented: $showingAuthenticationAlert) {
            Button("OK", role: .cancel) {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Please try again to view the capsule contents.")
        }
    }

    private var authenticatePrompt: some View {
        VStack {
            Text("Authentication Required")
                .font(.title)
                .padding()
            
            Button("Authenticate with Face ID/Touch ID") {
                authenticateUser()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var lockedContent: some View {
        VStack {
            Image(systemName: "lock.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            Text("This capsule is still locked")
                .font(.title2)
            Text("Unlocks on \(capsule.unlockDate, formatter: dateFormatter)")
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var capsuleContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(capsule.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Text("Unlock Date: \(capsule.unlockDate, formatter: dateFormatter)")
                    .font(.headline)
                    .foregroundColor(.purple)
                Divider()
                if capsule.mediaType == .message {
                    Text(capsule.message ?? "No message available.")
                        .multilineTextAlignment(.leading)
                        .padding(.vertical)
                } else if let mediaURL = capsule.mediaURL {
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
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                    .shadow(radius: 5)
                            case .failure:
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, maxHeight: 300)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    case .video:
                        VideoPlayer(player: AVPlayer(url: mediaURL))
                            .frame(maxWidth: .infinity)
                            .aspectRatio(16/9, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .shadow(radius: 5)
                    case .audio:
                        if FileManager.default.fileExists(atPath: mediaURL.path) {
                            AudioPlayerView(audioURL: mediaURL)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        } else {
                            Text("Audio file is missing.")
                                .foregroundColor(.red)
                        }
                    default:
                        Text("Unsupported media type.")
                            .foregroundColor(.red)
                    }
                } else {
                    Text("No media URL found")
                }
                Spacer()
            }
            .padding()
            .background(Color.white.opacity(0.9))
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding()
        }
        .navigationTitle("Capsule Details")
        .navigationBarItems(trailing: deleteButton)
        .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]), startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea())
    }

    private var deleteButton: some View {
        if capsule.unlockDate <= Date() {
            return AnyView(Button(action: deleteCapsule) {
                Image(systemName: "trash")
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

    private func authenticateUser() {
        Task {
            let success = await manager.authenticateUser()
            await MainActor.run {
                if success {
                    isAuthenticated = true
                } else {
                    showingAuthenticationAlert = true
                }
            }
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()
