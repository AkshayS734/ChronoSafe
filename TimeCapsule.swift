import Foundation
import UserNotifications
import AVFoundation

struct TimeCapsule: Identifiable, Codable {
    let id: UUID
    var title: String
    var unlockDate: Date
    var mediaType: MediaType
    var mediaURL: URL?
    var message: String?
    
    enum MediaType: String, Codable {
        case image, video, message, audio
    }
}

class TimeCapsuleManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var capsules: [TimeCapsule] = []
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private var audioRecorder: AVAudioRecorder?
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        requestNotificationPermission()
        loadCapsules()
        capsules.forEach { scheduleNotification(for: $0) }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func addCapsule(title: String, unlockDate: Date, mediaType: TimeCapsule.MediaType, mediaURL: URL?, message: String? = nil) {
        let newCapsule = TimeCapsule(id: UUID(), title: title, unlockDate: unlockDate, mediaType: mediaType, mediaURL: mediaURL, message: message)
        capsules.append(newCapsule)
        saveCapsules()
        scheduleNotification(for: newCapsule)
    }
    
    func scheduleNotification(for capsule: TimeCapsule) {
        let content = UNMutableNotificationContent()
        content.title = "Time Capsule Unlocked!"
        content.body = "Your capsule '\(capsule.title)' is now available to view."
        content.sound = .default
        content.userInfo = ["capsuleID": capsule.id.uuidString]

        let triggerDate = capsule.unlockDate
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate), repeats: false)

        let request = UNNotificationRequest(identifier: capsule.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func unlockCapsule(withID id: UUID) {
        if let index = capsules.firstIndex(where: { $0.id == id }) {
            objectWillChange.send()
            capsules[index].unlockDate = Date()
            saveCapsules()
        }
    }
    
    func loadCapsules() {
        let fileURL = documentsDirectory.appendingPathComponent("capsules.json")
        do {
            let data = try Data(contentsOf: fileURL)
            capsules = try JSONDecoder().decode([TimeCapsule].self, from: data)
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
    
    func deleteCapsule(withID id: UUID) {
        if let index = capsules.firstIndex(where: { $0.id == id }) {
            capsules.remove(at: index)
            saveCapsules()
        }
    }
    
    private func cleanupUnusedMediaFiles() {
        let activeURLs = Set(capsules.compactMap { $0.mediaURL })
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            for fileURL in directoryContents {
                if !activeURLs.contains(fileURL) && (fileURL.pathExtension == "jpg" || fileURL.pathExtension == "mp4" || fileURL.pathExtension == "m4a") {
                    try FileManager.default.removeItem(at: fileURL)
                }
            }
        } catch {
            print("Error cleaning up media files: \(error)")
        }
    }
}
