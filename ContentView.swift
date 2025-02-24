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
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.5), Color.purple.opacity(0.5)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                VStack {
                    if showWelcomeScreen {
                        WelcomeView(showWelcomeScreen: $showWelcomeScreen)
                    } else if manager.capsules.isEmpty {
                        VStack(spacing: 20) {
                            Text("No Time Capsules Yet!")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                                .multilineTextAlignment(.center)
                            
                            Text("Tap the button below to create your first one 🎁")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                            
                            Button(action: { showAddCapsule.toggle() }) {
                                Image(systemName: "plus.circle.fill")
                                    .resizable()
                                    .frame(width: 55, height: 55)
                                    .foregroundColor(.white)
                                    .shadow(color: .white.opacity(0.2), radius: 3, x: 0, y: 2)
                            }
                            .padding()
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.12))
                                    .blur(radius: 6)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                                    )
                            )
                            .buttonStyle(PlainButtonStyle())
                            .scaleEffect(1.05)
                            .animation(.easeInOut(duration: 0.3), value: showAddCapsule)
                        }
                        .padding(.vertical, 30)
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
                        .background(Color.clear)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle(showWelcomeScreen ? "" : "Time Capsules")
            .toolbar {
                if !showWelcomeScreen && !manager.capsules.isEmpty {
                    Button(action: { showAddCapsule.toggle() }) {
                        Image(systemName: "plus")
                    }
                    .foregroundColor(.white.opacity(0.8))
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
