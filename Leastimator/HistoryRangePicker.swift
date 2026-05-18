
import SwiftUI

struct HistoryRangePicker: View {
    @Binding var selectedRange: HistoryTimeRange
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(HistoryTimeRange.allCases) { range in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedRange = range
                    }
                }) {
                    Text(range.rawValue)
                        .font(.rounded(11))
                        .fontWeight(.medium)
                        .kerning(1)
                        .foregroundColor(selectedRange == range ? .black : .subText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            if selectedRange == range {
                                Capsule()
                                    .fill(Color.accentColor)
                                    .matchedGeometryEffect(id: "range_bg", in: rangeNamespace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.subBg.opacity(0.5))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.mainText.opacity(0.05), lineWidth: 1)
        )
    }
    
    @Namespace private var rangeNamespace
}

#Preview {
    HistoryRangePicker(selectedRange: .constant(.threeMonths))
        .padding()
        .background(Color.mainBg)
}
