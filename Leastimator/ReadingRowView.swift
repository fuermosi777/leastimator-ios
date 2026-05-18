
import SwiftUI

struct ReadingRowView: View {
    @ObservedObject var reading: OdoReading
    let previousReading: OdoReading?
    let unit: String
    
    var diff: Int64? {
        guard let prev = previousReading else { return nil }
        return reading.value - prev.value
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(reading.value) \(unit)")
                    .font(.rounded(15, weight: .medium))
                    .foregroundColor(.mainText)
                
                if let date = reading.date {
                    Text(date.format())
                        .font(.rounded(11))
                        .foregroundColor(.subText)
                }
            }
            
            Spacer()
            
            if let diff = diff {
                Text("+\(diff)")
                    .font(.rounded(12, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundColor(.accentColor)
                    .cornerRadius(6)
            }
        }
        .padding(.vertical, 12)
    }
}
