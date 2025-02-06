import SwiftUI
import UserNotifications
import PhotosUI
import AVKit

struct TimeCapsule: Identifiable, Codable {
    let id: UUID
    var title: String
    var unlockDate: Date
    var mediaType: MediaType
    var mediaURL: URL?
    var message: String?
    
    enum MediaType: String, Codable {
        case image, video, message
    }
}

class TimeCapsuleManager: ObservableObject {
    @Published var capsules: [TimeCapsule] = []
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    init() {
        loadCapsules()
    }
    
    func addCapsule(title: String, unlockDate: Date, mediaType: TimeCapsule.MediaType, mediaURL: URL?, message: String? = nil) {
        let newCapsule = TimeCapsule(
            id: UUID(),
            title: title,
            unlockDate: unlockDate,
            mediaType: mediaType,
            mediaURL: mediaURL,
            message: message
        )
        capsules.append(newCapsule)
        saveCapsules()
    }
    
    func loadCapsules() {
        let fileURL = documentsDirectory.appendingPathComponent("capsules.json")
        do {
            let data = try Data(contentsOf: fileURL)
            let loadedCapsules = try JSONDecoder().decode([TimeCapsule].self, from: data)
            capsules = loadedCapsules
        } catch {
            print("Error loading capsules: \(error)")
        }
    }
    func saveCapsules() {
        guard let data = try? JSONEncoder().encode(capsules) else { return }
        
        do {
            let fileURL = documentsDirectory.appendingPathComponent("capsules.json")
            try data.write(to: fileURL, options: [.atomicWrite])
            cleanupUnusedMediaFiles()
        } catch {
            print("Error saving capsules: \(error)")
        }
    }
    
    private func cleanupUnusedMediaFiles() {
        let activeURLs = Set(capsules.compactMap { $0.mediaURL })
        
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            
            for fileURL in directoryContents {
                if !activeURLs.contains(fileURL) &&
                    (fileURL.pathExtension == "jpg" || fileURL.pathExtension == "mp4") {
                    try FileManager.default.removeItem(at: fileURL)
                }
            }
        } catch {
            print("Error cleaning up media files: \(error)")
        }
    }
}

struct ContentView: View {
    @StateObject private var manager = TimeCapsuleManager()
    @State private var showWelcomeScreen = true
    @State private var showAddCapsule = false
    
    var body: some View {
        NavigationView {
            VStack {
                if showWelcomeScreen {
                    WelcomeView(showWelcomeScreen: $showWelcomeScreen)
                } else {
                    List {
                        ForEach(manager.capsules) { capsule in
                            if Date() >= capsule.unlockDate {
                                NavigationLink(destination: CapsuleDetailView(capsule: capsule)) {
                                    CapsuleRow(capsule: capsule)
                                }
                            } else {
                                CapsuleRow(capsule: capsule)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .navigationTitle("Time Capsules")
                    .toolbar {
                        Button(action: { showAddCapsule.toggle() }) {
                            Image(systemName: "plus")
                        }
                    }
                    .sheet(isPresented: $showAddCapsule) {
                        AddCapsuleView(manager: manager)
                    }
                }
            }
        }
    }
}

struct WelcomeView: View {
    @Binding var showWelcomeScreen: Bool
    
    var body: some View {
        VStack {
            Spacer()
            Text("Welcome to Time Capsule!")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.green)
                .padding(.bottom, 20)
                .multilineTextAlignment(.center)
            Text("Store your special memories\nand open them later!")
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.bottom, 30)
            Image(systemName: "gift.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
                .padding(.bottom, 40)
            Button(action: {
                showWelcomeScreen = false
            }) {
                Text("Start Exploring")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: 250)
                    .background(Color.green)
                    .cornerRadius(25)
                    .shadow(radius: 10)
            }
            .padding(.bottom, 40)
            Spacer()
            Text("Made with 💚 for your memories")
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(30)
        .padding(20)
    }
}

struct CapsuleRow: View {
    let capsule: TimeCapsule
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(capsule.title)
                    .font(.headline)
                Text("Unlocks on \(capsule.unlockDate, formatter: dateFormatter)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: Date() >= capsule.unlockDate ? "lock.open.fill" : "lock.fill")
                .foregroundColor(Date() >= capsule.unlockDate ? .green : .red)
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

struct AddCapsuleView: View {
    @ObservedObject var manager: TimeCapsuleManager
    @State private var title = ""
    @State private var unlockDate = Date()
    @State private var selectedMedia: PhotosPickerItem?
    @State private var mediaType: TimeCapsule.MediaType = .message
    @State private var message: String = ""  // New state for message media type
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                DatePicker("Unlock Date", selection: $unlockDate)
                
                Picker("Media Type", selection: $mediaType) {
                    Text("Image").tag(TimeCapsule.MediaType.image)
                    Text("Video").tag(TimeCapsule.MediaType.video)
                    Text("Message").tag(TimeCapsule.MediaType.message)
                }
                
                if mediaType != .message {
                    PhotosPicker(
                        selection: $selectedMedia,
                        matching: mediaType == .image ? .images : .videos
                    ) {
                        Text("Select Media")
                    }
                } else {
                    TextField("Enter your message", text: $message)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Button("Save Capsule") {
                    Task {
                        await saveCapsule()
                    }
                }
                .disabled(title.isEmpty)
            }
            .navigationTitle("New Time Capsule")
            .toolbar {
                Button("Cancel") { presentationMode.wrappedValue.dismiss() }
            }
        }
    }
    
    private func saveCapsule() async {
        guard !title.isEmpty else { return }
        
        var mediaURL: URL?
        if let selectedItem = selectedMedia {
            mediaURL = await saveMediaToDocuments(selectedItem)
        }
        
        manager.addCapsule(
            title: title,
            unlockDate: unlockDate,
            mediaType: mediaType,
            mediaURL: mediaURL,
            message: mediaType == .message ? message : nil
        )
        presentationMode.wrappedValue.dismiss()
    }
    
    private func saveMediaToDocuments(_ item: PhotosPickerItem) async -> URL? {
        do {
            let filename = "\(UUID().uuidString).\((mediaType == .image) ? "jpg" : "mp4")"
            let fileURL = manager.documentsDirectory.appendingPathComponent(filename)
            
            let mediaData = try await item.loadTransferable(type: Data.self)
            try mediaData?.write(to: fileURL, options: [.atomicWrite])
            
            return fileURL
        } catch {
            print("Error saving media: \(error)")
            return nil
        }
    }
}

struct CapsuleDetailView: View {
    let capsule: TimeCapsule
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(capsule.title)
                .font(.largeTitle)
            
            Text("Unlock Date: \(capsule.unlockDate, formatter: dateFormatter)")
                .foregroundColor(.secondary)
            
            Divider()
            
            if let mediaURL = capsule.mediaURL {
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
                    VideoPlayer(player: AVPlayer(url: mediaURL))
                        .frame(maxWidth: .infinity)
                        .aspectRatio(16/9, contentMode: .fit)
                    
                case .message:
                    Text(capsule.message ?? "")
                        .multilineTextAlignment(.leading)
                        .padding()
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Capsule Details")
    }
}
