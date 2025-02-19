import SwiftUI

struct CapsuleRow: View {
    let capsule: TimeCapsule
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(capsule.title)
                    .font(.headline)
                Text("\(Date() >= capsule.unlockDate ? "Unlocked on" : "Unlocks on") \(capsule.unlockDate, formatter: dateFormatter)")
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
