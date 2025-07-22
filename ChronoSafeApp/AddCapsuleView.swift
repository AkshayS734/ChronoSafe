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
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Title Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.headline)
                                .foregroundColor(.primary.opacity(0.8))
                            TextField("Enter capsule title", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                        
                        // Date Picker Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Unlock Date")
                                .font(.headline)
                                .foregroundColor(.primary.opacity(0.8))
                            DatePicker("", selection: $unlockDate, in: Date()...)
                                .datePickerStyle(.graphical)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                        
                        // Media Type Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Media Type")
                                .font(.headline)
                                .foregroundColor(.primary.opacity(0.8))
                            HStack(spacing: 12) {
                                ForEach([TimeCapsule.MediaType.message,
                                        .image, .video, .audio], id: \.self) { type in
                                    MediaTypeButton(
                                        type: type,
                                        isSelected: mediaType == type,
                                        action: { mediaType = type }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Content Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Content")
                                .font(.headline)
                                .foregroundColor(.primary.opacity(0.8))
                            
                            switch mediaType {
                            case .message:
                                TextEditor(text: $message)
                                    .frame(height: 150)
                                    .padding()
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                            case .image, .video:
                                MediaPickerButton(
                                    mediaType: mediaType,
                                    showPicker: $showCameraPicker,
                                    mediaURL: $mediaURL
                                )
                            case .audio:
                                AudioRecordingView(
                                    recording: $recording,
                                    elapsedTime: $elapsedTime,
                                    audioRecorder: $audioRecorder,
                                    mediaURL: $mediaURL
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("New Time Capsule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        saveAndDismiss()
                    }
                    .disabled(title.isEmpty)
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
    
    private func saveAndDismiss() {
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

struct MediaTypeButton: View {
    let type: TimeCapsule.MediaType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: iconName)
                    .font(.system(size: 24))
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.white.opacity(0.9))
            .foregroundColor(isSelected ? .blue : .primary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    private var iconName: String {
        switch type {
        case .message: return "text.bubble"
        case .image: return "photo"
        case .video: return "video"
        case .audio: return "mic"
        }
    }
    
    private var title: String {
        switch type {
        case .message: return "Text"
        case .image: return "Photo"
        case .video: return "Video"
        case .audio: return "Audio"
        }
    }
}

struct MediaPickerButton: View {
    let mediaType: TimeCapsule.MediaType
    @Binding var showPicker: Bool
    @Binding var mediaURL: URL?
    
    var body: some View {
        Button(action: { showPicker = true }) {
            VStack {
                Image(systemName: mediaType == .image ? "photo" : "video")
                    .font(.system(size: 30))
                Text(mediaType == .image ? "Take/Choose Photo" : "Record/Choose Video")
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
            .background(Color.white.opacity(0.9))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .foregroundColor(.blue)
    }
}

struct AudioRecordingView: View {
    @Binding var recording: Bool
    @Binding var elapsedTime: Int
    @Binding var audioRecorder: AVAudioRecorder?
    @Binding var mediaURL: URL?
    @State private var showMediaPicker = false
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 16) {
            // Recording status and timer
            HStack {
                Image(systemName: recording ? "waveform" : "waveform.circle")
                    .font(.system(size: 24))
                    .foregroundColor(recording ? .red : .gray)
                Text(recording ? "Recording..." : "Ready to record")
                    .font(.headline)
                    .foregroundColor(recording ? .red : .gray)
                Spacer()
                Text(formattedTime(elapsedTime))
                    .font(.system(.title3, design: .monospaced))
                    .foregroundColor(recording ? .red : .gray)
            }
            .padding()
            .background(Color.white.opacity(0.9))
            .cornerRadius(12)
            
            // Media options
            HStack(spacing: 16) {
                // Record button
                Button(action: {
                    if recording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: recording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.system(size: 48))
                        Text(recording ? "Stop" : "Record")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.white.opacity(0.9))
                    .foregroundColor(recording ? .red : .blue)
                    .cornerRadius(12)
                }
                
                // Choose from library button
                Button(action: { showMediaPicker = true }) {
                    VStack(spacing: 8) {
                        Image(systemName: "folder.circle.fill")
                            .font(.system(size: 48))
                        Text("Choose File")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.white.opacity(0.9))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
                }
            }
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .sheet(isPresented: $showMediaPicker) {
            DocumentPicker(mediaURL: $mediaURL)
        }
        .onChange(of: recording) { newValue in
            if newValue {
                startTimer()
            } else {
                stopTimer()
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func startRecording() {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("\(UUID().uuidString).m4a")
        
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            recording = true
            elapsedTime = 0 // Reset timer when starting new recording
        } catch {
            print("Recording failed: \(error)")
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        recording = false
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Could not deactivate audio session: \(error)")
        }
    }
    
    private func formattedTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var mediaURL: URL?
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Create a copy in the app's document directory
            let fileManager = FileManager.default
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsPath.appendingPathComponent(url.lastPathComponent)
            
            do {
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                try fileManager.copyItem(at: url, to: destinationURL)
                parent.mediaURL = destinationURL
            } catch {
                print("Error copying file: \(error)")
            }
        }
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
