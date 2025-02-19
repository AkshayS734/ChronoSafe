import SwiftUI
import _AVKit_SwiftUI
import AVFoundation
import PhotosUI

struct AddCapsuleView: View {
    @ObservedObject var manager: TimeCapsuleManager
    @State private var title = ""
    @State private var unlockDate = Date()
    @State private var mediaType: TimeCapsule.MediaType = .message
    @State private var message: String = ""
    @State private var mediaURL: URL?
    @State private var showCameraPicker = false
    @State private var showVideoPicker = false
    @State private var recording = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var elapsedTime: Int = 0
    @State private var timer: Timer?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                DatePicker("Unlock Date", selection: $unlockDate)
                
                Picker("Select Item type", selection: $mediaType) {
                    Text("Message").tag(TimeCapsule.MediaType.message)
                    Text("Image").tag(TimeCapsule.MediaType.image)
                    Text("Video").tag(TimeCapsule.MediaType.video)
                    Text("Voice Note").tag(TimeCapsule.MediaType.audio)
                }
                
                if mediaType == .image {
                    Button("Capture Image") {
                        showCameraPicker = true
                    }
                } else if mediaType == .video {
                    Button("Record Video") {
                        showVideoPicker = true
                    }
                } else if mediaType == .audio {
                    VStack {
                        Button(recording ? "Stop Recording" : "Record Voice Note") {
                            recording ? stopRecording() : startRecording()
                        }
                        if recording {
                            Text("Recording: \(formattedElapsedTime())")
                                .font(.headline)
                                .foregroundColor(.red)
                        }
                    }
                } else {
                    TextEditor(text: $message)
                        .frame(minHeight: 40, maxHeight: 100)
                        .background(Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                if let mediaURL = mediaURL {
                    if mediaType == .image {
                        if let imageData = try? Data(contentsOf: mediaURL),
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(10)
                        }
                    } else if mediaType == .video {
                        VideoPlayer(player: AVPlayer(url: mediaURL))
                            .frame(height: 200)
                            .cornerRadius(10)
                    } else if mediaType == .audio {
                        AudioPlayerView(audioURL: mediaURL)
                            .frame(height: 50)
                    }
                }
            }
            .navigationTitle("New Time Capsule")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCapsule()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showCameraPicker) {
                CameraPicker(mediaType: .image, onCapture: { url in
                    mediaURL = url
                })
            }
            .sheet(isPresented: $showVideoPicker) {
                CameraPicker(mediaType: .video, onCapture: { url in
                    mediaURL = url
                })
            }
        }
    }
    
    private func saveCapsule() {
        guard !title.isEmpty else { return }
        
        manager.addCapsule(
            title: title,
            unlockDate: unlockDate,
            mediaType: mediaType,
            mediaURL: mediaURL,
            message: mediaType == .message ? message : nil
        )
        presentationMode.wrappedValue.dismiss()
    }
    
    private func startRecording() {
        let filename = "voice_\(title).m4a"
        let fileURL = manager.documentsDirectory.appendingPathComponent(filename)
        
        print("Starting recording at URL: \(fileURL.path)")
        
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.record()
            recording = true
            mediaURL = fileURL
            print(mediaURL?.path ?? "No url")
            startTimer()
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        recording = false
        stopTimer()
        if let url = mediaURL {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: url.path) {
                print("File exists at: \(url.path)")
            } else {
                print("File does not exist at: \(url.path)")
            }
        }
    }
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                elapsedTime += 1
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func formattedElapsedTime() -> String {
        let minutes = elapsedTime / 60
        let seconds = elapsedTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    let mediaType: TimeCapsule.MediaType
    var onCapture: (URL) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.mediaTypes = [mediaType == .image ? "public.image" : "public.movie"]
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker
        
        init(_ parent: CameraPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let mediaURL = info[.mediaURL] as? URL {
                parent.onCapture(mediaURL)
            } else if let image = info[.originalImage] as? UIImage {
                let filename = "photo_\(UUID().uuidString).jpg"
                let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    try? imageData.write(to: fileURL)
                    parent.onCapture(fileURL)
                }
            }
            picker.dismiss(animated: true)
        }
    }
}
