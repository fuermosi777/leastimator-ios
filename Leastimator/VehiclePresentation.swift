//
//  VehiclePresentation.swift
//  Leastimator
//
//  Created by Hao Liu on 3/28/21.
//

import SwiftUI
import iLineChart
import SwiftUIPager
import SwiftRater

// The type of content shown in the hero dashboard section of the presentation page.
enum DashboardType {
  case estimation,
       shouldRead
}

enum Sheet: Identifiable {
  case readingCreation,
       readingList,
       vehicleEdit
  var id: Int { hashValue }
}

struct InfoPanel: View {
  var title: String
  var unit: String
  var value: String
  
  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .foregroundColor(.gray)
      HStack(alignment: .bottom) {
        Text(value)
        Text(unit)
          .foregroundColor(.gray)
      }
    }
    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
  }
}

struct MoreInfoView: View {
  var question: String
  var answer: String
  var body: some View {
    Text(question)
      .foregroundColor(.gray)
    Spacer().frame(height: 10.0)
    Text(answer)
  }
}

struct VehiclePresentation: View {
  @Environment(\.managedObjectContext) private var viewContext
  
  @AppStorage("lineChartShowOriginalData") private var lineChartShowOriginalData = false
  
  // Add ObservedObject make sure it gets updated data.
  @ObservedObject var vehicle: Vehicle
  
  private var readingsRequest: FetchRequest<OdoReading>
  private var readings: FetchedResults<OdoReading>{readingsRequest.wrappedValue}
  
  @State var activeSheet: Sheet?
  
  let dashboardTypes: [DashboardType] = [.estimation, .shouldRead]
  @StateObject var dashboardPage: Page = .first()
  @State private var dashboardIndex = 0
  
  init(vehicle: Vehicle) {
    self.vehicle = vehicle
    self.readingsRequest = FetchRequest(entity: OdoReading.entity(),
                                        sortDescriptors: [NSSortDescriptor(keyPath: \OdoReading.date, ascending: true)],
                                        predicate: NSPredicate(format: "%K == %@", #keyPath(OdoReading.vehicle), vehicle))
  }
  
  var extendedInfo: ExtendedVehicleInfo {
    Compute(vehicle, readings.map{ $0 })
  }
  
  var lengthUnit: LengthUnit {
    get {
      if let unit = LengthUnit(rawValue: vehicle.lengthUnit) {
        return unit
      } else {
        return LengthUnit.mi
      }
    }
  }
  
  var currency: Currency {
    get {
      if let curr = Currency(rawValue: vehicle.currency ?? "usd") {
        return curr
      } else {
        return Currency.usd
      }
    }
  }
  
  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack {
        Pager(page: dashboardPage,
              data: dashboardTypes,
              id: \.self,
              content: { index in
                switch index {
                case .estimation:
                  if let normalPredicatedMileage = extendedInfo.normalPredicatedMileage {
                    ProgressCircle(progress: Float(Float(normalPredicatedMileage) / Float(vehicle.allowed))) {
                      VStack {
                        Text("Estimate")
                          .font(.callout)
                          .foregroundColor(.subText)
                        Text("\(normalPredicatedMileage)")
                          .font(.title)
                        Text(lengthUnit.longNames)
                          .font(.callout)
                          .foregroundColor(.subText)
                      }
                    }
                    .frame(width: 150.0, height: 150.0)
                    .padding(40.0)
                  } else {
                    ProgressCircle(progress: 0.0) {
                      VStack {
                        Text("Not enough data")
                          .font(.callout)
                          .foregroundColor(.subText)
                      }
                    }
                    .frame(width: 150.0, height: 150.0)
                    .padding(40.0)
                  }
                case .shouldRead:
                  VStack {
                    Text("Odometer should read less than")
                      .font(.callout)
                      .foregroundColor(.subText)
                    Text(extendedInfo.mileageShouldLessThan.toOdometerReading())
                      .font(.custom("Menlo", size: 22.0))
                      .padding(.vertical, 10.0)
                      .padding(.horizontal, 20.0)
                      .foregroundColor(.lightGray)
                      .background(Color.subBg)
                      .clipShape(RoundedRectangle(cornerRadius: 6))
                  }
                }
              })  // Pager
          .frame(height: 240)
          .onChange(of: dashboardPage.index) {
            dashboardIndex = $0
          }
        PagerIndicator(size: dashboardTypes.count, focusIndex: $dashboardIndex)
          .padding(.bottom, 20.0)
        
        // Actions
        VStack(alignment: .leading) {
          Button(action: { self.activeSheet = .readingCreation }) {
            Label("Add odometer reading", systemImage: "plus")
          }
          Divider()
          
          Button(action: { self.activeSheet = .readingList }) {
            Label("Reading history", systemImage: "clock")
          }
          Divider()
        }
        
        // Basic info
        VStack(alignment: .leading) {
          HStack {
            InfoPanel(title: "Current mileage", unit: lengthUnit.shortFor, value: String(extendedInfo.currentMileage))
            InfoPanel(title: "Unused mileage", unit: lengthUnit.shortFor, value: String(extendedInfo.leftMileage))
          }
          Divider()
          
          if let mileagePerDay = extendedInfo.mileagePerDay, let mileagePerMonth = extendedInfo.mileagePerMonth {
            HStack {
              InfoPanel(title: "Daily behavior", unit: lengthUnit.shortFor, value: String(mileagePerDay))
              InfoPanel(title: "Monthly behavior", unit: lengthUnit.shortFor, value: String(mileagePerMonth))
            }
            Divider()
          }
          
          if let excessMileage = extendedInfo.excessMileage, let excessCharge = extendedInfo.excessCharge {
            HStack {
              InfoPanel(title: "Excess mileage", unit: lengthUnit.shortFor, value: String(excessMileage))
              InfoPanel(title: "Excess charge", unit: currency.rawValue, value: String(excessCharge))
            }
            Divider()
          }
        }
        
        // Mileage accumlation
        if extendedInfo.mileageSnapshots.count > 0 {
          Spacer()
          iLineChart(data: lineChartShowOriginalData ?
                      extendedInfo.mileageSnapshotsOriginal :
                      extendedInfo.mileageSnapshots,
                     title: "Mileage history",
                     chartBackgroundGradient: GradientColor(start: .neonBlue, end: .mainBg),
                     canvasBackgroundColor: .mainBg,
                     titleColor: .mainText,
                     numberColor: .subText,
                     displayChartStats: true,
                     minHeight: 100.0,
                     maxHeight: 100.0,
                     titleFont: .system(size: 20, weight: .regular),
                     dataFont: .system(size: 16, weight: .regular),
                     floatingPointNumberFormat: "%.0f")
            .frame(height: 100)
            .padding(.vertical, 50)
          
          Divider()
        }
        
        // More/other info
        VStack(alignment: .leading) {
          MoreInfoView(question: "What should my odometer read?",
                       answer: "Your odometer should currently read less than \(extendedInfo.mileageShouldLessThan) \(lengthUnit.longNames).")
          Divider()
          
          MoreInfoView(question: "How long can I drive today?",
                       answer: "You can drive up to \(extendedInfo.maxDriveToday) \(lengthUnit.longNames) today and still be on track.")
          Divider()
          
          MoreInfoView(question: "How long is my lease left?",
                       answer: extendedInfo.isExpired ?
                        "Congratulations, your lease is expired." :
                        "You have \(extendedInfo.leaseLeft) months left. Keep up the work!")
          Divider()
        }
        
        Spacer()
      }  // VStack
    }  // ScrollView
    .padding(10.0)
    .navigationBarTitle(vehicle.name ?? "",
                        displayMode: .inline)
    .navigationBarItems(
      trailing:
        Button(action: { activeSheet = .vehicleEdit }) {
          Image(systemName: "slider.horizontal.3")
        }
    )
    .sheet(item: $activeSheet) { item in
      switch item {
      case .readingCreation:
        EditReadingView(vehicle: vehicle, onDismiss: handleSheetDismiss)
          .environment(\.managedObjectContext, viewContext)
      case .readingList:
        ReadingList(vehicle: vehicle,
                    onDismiss: handleSheetDismiss )
          .environment(\.managedObjectContext, viewContext)
      case .vehicleEdit:
        EditVehicleView(vehicle: vehicle, onDismiss: handleSheetDismiss)
      }
    }
    .onAppear {
      SwiftRater.check()
    }
  }
  
  private func handleSheetDismiss() {
    activeSheet = nil
  }
}

