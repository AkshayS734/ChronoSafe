import SwiftUI
import UserNotifications

struct ContentView: View {
    @StateObject private var manager = TimeCapsuleManager()
    @State private var showWelcomeScreen = true
    @State private var showAddCapsule = false
    @State private var currentTime = Date()
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.5), Color.purple.opacity(0.5)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    if showWelcomeScreen {
                        WelcomeView(showWelcomeScreen: $showWelcomeScreen)
                    } else if manager.capsules.isEmpty {
                        EmptyStateView(showAddCapsule: $showAddCapsule)
                    } else {
                        CapsuleListView(
                            manager: manager,
                            currentTime: currentTime,
                            showAddCapsule: $showAddCapsule
                        )
                    }
                }
            }
            .navigationTitle(showWelcomeScreen ? "" : "Time Capsules")
            .toolbar {
                if !showWelcomeScreen && !manager.capsules.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        AddButton(showAddCapsule: $showAddCapsule)
                    }
                }
            }
            .sheet(isPresented: $showAddCapsule) {
                AddCapsuleView(manager: manager)
            }
            .onAppear {
                startTimer()
            }
        }
    }
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

// New supporting views
struct EmptyStateView: View {
    @Binding var showAddCapsule: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "capsule")
                .font(.system(size: 60))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2)
            
            VStack(spacing: 12) {
                Text("No Time Capsules Yet!")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Create your first memory capsule")
                    .font(.body)
            }
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            
            Button(action: { showAddCapsule.toggle() }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Capsule")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.white)
                .foregroundColor(.blue)
                .cornerRadius(25)
                .shadow(color: .black.opacity(0.1), radius: 5)
            }
        }
        .padding()
    }
}

struct CapsuleListView: View {
    @ObservedObject var manager: TimeCapsuleManager
    let currentTime: Date
    @Binding var showAddCapsule: Bool
    
    var body: some View {
        List {
            if !lockedCapsules.isEmpty {
                Section(header: 
                    Text("Locked")
                        .font(.headline)
                        .foregroundColor(.white)
                ) {
                    ForEach(lockedCapsules) { capsule in
                        CapsuleRow(capsule: capsule)
                            .listRowBackground(Color.white.opacity(0.9))
                    }
                }
            }
            
            if !unlockedCapsules.isEmpty {
                Section(header: 
                    Text("Unlocked")
                        .font(.headline)
                        .foregroundColor(.white)
                ) {
                    ForEach(unlockedCapsules) { capsule in
                        NavigationLink(destination: CapsuleDetailView(capsule: capsule, manager: manager)) {
                            CapsuleRow(capsule: capsule)
                        }
                        .listRowBackground(Color.white.opacity(0.9))
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .scrollContentBackground(.hidden)
    }
    
    private var lockedCapsules: [TimeCapsule] {
        manager.capsules
            .filter { $0.unlockDate > currentTime }
            .sorted { $0.unlockDate < $1.unlockDate }
    }
    
    private var unlockedCapsules: [TimeCapsule] {
        manager.capsules
            .filter { $0.unlockDate <= currentTime }
            .sorted { $0.unlockDate > $1.unlockDate }
    }
}

struct AddButton: View {
    @Binding var showAddCapsule: Bool
    
    var body: some View {
        Button(action: { showAddCapsule.toggle() }) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.2), radius: 2)
        }
    }
}

#Preview {
    ContentView()
}
