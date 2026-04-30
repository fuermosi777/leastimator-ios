import sys

file_path = 'Leastimator/VehiclePresentation.swift'
with open(file_path, 'r') as f:
    content = f.read()

target = """          HStack(spacing: 12) {
            if vehicle.archived {
              Text("Archived")
                .font(.inter(11, weight: .bold))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            if vehicle.teslaConnectionId != nil {
              HStack(spacing: 6) {
                Image(systemName: vehicleState?.lowercased() == "online" ? "bolt.car.fill" : "moon.zzz.fill")
                Text("API: \(vehicleState?.capitalized ?? "Checking...")")
              }
              .font(.inter(11, weight: .bold))
              .foregroundColor(vehicleState?.lowercased() == "online" ? .green : .subText)
              .padding(.horizontal, 10).padding(.vertical, 6)
              .background(Color.subBg.opacity(0.3))
              .overlay(
                  RoundedRectangle(cornerRadius: 12)
                      .stroke(Color.mainText.opacity(0.05), lineWidth: 1)
              )
              .cornerRadius(12)
            }
          }
          .padding(.top, 8)

          CoachMessage(isOverPace: progressPercentage >= 1.0)"""

replacement = """          if vehicle.archived {
            Text("Archived")
              .font(.inter(11, weight: .bold))
              .padding(.horizontal, 12).padding(.vertical, 6)
              .background(Color.orange)
              .foregroundColor(.white)
              .cornerRadius(12)
              .padding(.top, 8)
          }

          HStack(alignment: .center) {
            CoachMessage(isOverPace: progressPercentage >= 1.0)
            Spacer()
            if vehicle.teslaConnectionId != nil {
              TeslaAPIStatusView(state: vehicleState)
            }
          }
          .padding(.top, vehicle.archived ? 0 : 8)"""

if target in content:
    new_content = content.replace(target, replacement)
    with open(file_path, 'w') as f:
        f.write(new_content)
    print("Replacement successful")
else:
    print("Target not found")
    # Let's see what's different
    start_index = content.find('          HStack(spacing: 12) {')
    if start_index != -1:
        print("Start found at index", start_index)
        print("Context:")
        print(content[start_index:start_index + 200])
    else:
        print("Start NOT found")
