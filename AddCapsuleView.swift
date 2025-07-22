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
            ScrollView {
                VStack(spacing: 20) {
                    Text("Create a Time Capsule")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.teal)
//                        .padding(.top, 20)

                    VStack(spacing: 15) {
                        TextField("Capsule Title", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(radius: 3)

                        DatePicker("Unlock Date", selection: $unlockDate)
                            .datePickerStyle(.graphical)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(radius: 3)

                        Picker("Select Type", selection: $mediaType) {
                            Text("Message").tag(TimeCapsule.MediaType.message)
                            Text("Image").tag(TimeCapsule.MediaType.image)
                            Text("Video").tag(TimeCapsule.MediaType.video)
                            Text("Voice Note").tag(TimeCapsule.MediaType.audio)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.vertical)
                    }
                    .padding()
//                    .background(Color.blue.opacity(0.2))
//                    .cornerRadius(15)
//                    .padding(.horizontal)
//                    .padding(.bottom)

                    if mediaType == .image {
                        CapsuleButton(title: "Capture Image", action: { showCameraPicker = true })
                    } else if mediaType == .video {
                        CapsuleButton(title: "Record Video", action: { showVideoPicker = true })
                    } else if mediaType == .audio {
                        VStack {
                            CapsuleButton(title: recording ? "Stop Recording" : "Record Voice Note", action: {
                                recording ? stopRecording() : startRecording()
                            })
                            if recording {
                                Text("Recording: \(formattedElapsedTime())")
                                    .font(.headline)
                                    .foregroundColor(.red)
                            }
                        }
                    } else {
                        TextEditor(text: $message)
                            .frame(minHeight: 100, maxHeight: 150)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(radius: 3)
                    }

                    if let mediaURL = mediaURL {
                        CapsuleMediaPreview(mediaType: mediaType, mediaURL: mediaURL)
                    }

                    Spacer()
                }
                .padding()
            }
            .background(Color(.systemGray6))
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveCapsule() }.disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showCameraPicker) {
                CameraPicker(mediaType: .image, onCapture: { url in mediaURL = url })
            }
            .sheet(isPresented: $showVideoPicker) {
                CameraPicker(mediaType: .video, onCapture: { url in mediaURL = url })
            }
        }
    }
    
    private func saveCapsule() {
        guard !title.isEmpty else { return }
        print("Saving media URL :", mediaURL?.absoluteString ?? "No URL")
        manager.addCapsule(title: title, unlockDate: unlockDate, mediaType: mediaType, mediaURL: mediaURL, message: mediaType == .message ? message : nil)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func startRecording() {
        let filename = "voice_\(UUID().uuidString).m4a"
        let fileURL = manager.documentsDirectory.appendingPathComponent(filename)

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue 
        ]

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: .defaultToSpeaker)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            
            recording = true
            mediaURL = fileURL
            startTimer()
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        recording = false
        stopTimer()

        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session:", error.localizedDescription)
        }

        if let mediaURL = mediaURL {
            if FileManager.default.fileExists(atPath: mediaURL.path) {
                print("Audio file exists at :", mediaURL.absoluteString)
            } else {
                print("Audio file missing!")
            }
        } else {
            print("mediaURL is nil")
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

struct CapsuleButton: View {
    var title: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(.teal)
                .foregroundColor(.white)
                .clipShape(Capsule())
                .shadow(radius: 3)
        }
        .padding(.horizontal)
    }
}

struct CapsuleMediaPreview: View {
    let mediaType: TimeCapsule.MediaType
    let mediaURL: URL?
    
    var body: some View {
        if let mediaURL = mediaURL, FileManager.default.fileExists(atPath: mediaURL.path) {
            switch mediaType {
            case .image:
                if let image = UIImage(contentsOfFile: mediaURL.path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(10)
                }
                
            case .video:
                VideoPlayer(player: AVPlayer(url: mediaURL))
                    .frame(height: 200)
                    .cornerRadius(10)
                
            case .audio:
                AudioPlayerView(audioURL: mediaURL)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 3)
                
            default:
                EmptyView()
            }
        }
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
