import SwiftUI
import UserNotifications


struct ContentView: View {
    @StateObject private var manager = TimeCapsuleManager()
    @State private var showWelcomeScreen = true
    @State private var showAddCapsule = false
    @State private var currentTime = Date()

    var body: some View {
        NavigationView {
            VStack {
                if showWelcomeScreen {
                    WelcomeView(showWelcomeScreen: $showWelcomeScreen)
                } else {
                    List {
                        let lockedCapsules = manager.capsules.filter { $0.unlockDate > currentTime }
                            .sorted { $0.unlockDate < $1.unlockDate }
                        let unlockedCapsules = manager.capsules.filter { $0.unlockDate <= currentTime }
                            .sorted { $0.unlockDate > $1.unlockDate }

                        ForEach(lockedCapsules) { capsule in
                            CapsuleRow(capsule: capsule)
                                .foregroundColor(.gray)
                        }
                        
                        ForEach(unlockedCapsules) { capsule in
                            NavigationLink(destination: CapsuleDetailView(capsule: capsule, manager: manager)) {
                                CapsuleRow(capsule: capsule)
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
                    .onAppear {
                        startTimer()
//                        requestPhotoLibraryPermission()
                    }
                }
            }
        }
    }
//    private func requestPhotoLibraryPermission() {
//        PHPhotoLibrary.requestAuthorization { status in
//            switch status {
//            case .authorized:
//                print("Photo library access granted")
//            case .denied, .restricted:
//                print("Photo library access denied")
//            case .notDetermined:
//                print("Photo library access not determined yet")
//            default:
//                print("Unknown photo library status")
//                
//            }
//        }
//    }
    private func startTimer() {
        let now = Date()
        let calendar = Calendar.current
        let nextMinute = calendar.date(byAdding: .minute, value: 1, to: now)!
        let nextMinuteStart = calendar.date(bySetting: .second, value: 0, of: nextMinute)!
        
        let delay = nextMinuteStart.timeIntervalSince(now)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.currentTime = Date()
            self.startTimer()
        }
    }
}
