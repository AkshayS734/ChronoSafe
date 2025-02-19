import SwiftUI

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
            Button(action: { showWelcomeScreen = false }) {
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
