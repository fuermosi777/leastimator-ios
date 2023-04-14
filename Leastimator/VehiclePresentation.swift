//
//  VehiclePresentation.swift
//  Leastimator
//
//  Created by Hao Liu on 3/28/21.
//

import SwiftUI
import SwiftRater


enum Sheet: Identifiable {
  case readingCreation,
       vehicleEdit
  var id: Int { hashValue }
}

struct InfoPanel: View {
  var title: Text
  var unit: Text
  var value: Text
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      title
        .foregroundColor(.subText)
      HStack(alignment: .bottom) {
        value
          .font(.system(size: 24, weight: .bold, design: .rounded))
        unit
          .foregroundColor(.subText)
      }
    }
    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
  }
}

struct MoreInfoView: View {
  var question: Text
  var answer: Text
  var more: Text
  
  @State private var showMore = false
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        question
          .foregroundColor(.subText)
        Button(action: { showMore = true }) {
          Image(systemName: "info.circle").foregroundColor(.subText)
        }.sheet(isPresented: $showMore) {
          more
            .padding()
            .foregroundColor(.subText)
            .presentationDetents([.medium, .fraction(0.4)])
        }
      }
      Spacer().frame(height: 10.0)
      answer
    }
  }
}

struct VehiclePresentation: View {
  @Environment(\.managedObjectContext) private var viewContext
  @EnvironmentObject private var purchaseManager: PurchaseManager
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  
  // Add ObservedObject make sure it gets updated data.
  @ObservedObject var vehicle: Vehicle
  
  private var readingsRequest: FetchRequest<OdoReading>
  private var readings: FetchedResults<OdoReading>{readingsRequest.wrappedValue}
  
  @State var activeSheet: Sheet?
  
  @State private var dashboardIndex = 0
  
  @State var chartTapValue: Int? = 0
  
  @State var graphType: GraphType = .monthly
  
  enum GraphType {
    case monthly, daily
  }
  
  init(vehicle: Vehicle) {
    self.vehicle = vehicle
    self.readingsRequest = FetchRequest(entity: OdoReading.entity(),
                                        sortDescriptors: [NSSortDescriptor(keyPath: \OdoReading.date, ascending: true)],
                                        predicate: NSPredicate(format: "%K == %@", #keyPath(OdoReading.vehicle), vehicle))
  }
  
  // TODO: currently this gets called every time. Change to only call once.
  var extendedInfo: ExtendedVehicleInfo {
    Compute(vehicle, readings.map{ $0 })
  }
  
  var lengthUnit: LengthUnit {
    get {
      if let unit = LengthUnit(rawValue: vehicle.lengthUnit) {
        return unit
      } else {
        return .Imperial
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
  
  var progressPercentage: Float {
    let up = Float(extendedInfo.normalPredicatedMileage)
    let down = Float(vehicle.allowed + vehicle.starting)
    if down > 0 {
      return Float(up / down)
    }
    return 1.0
  }
  
  
  var body: some View {
    List {
      Section {
        HStack {
          Spacer()
          ProgressCircle(progress: progressPercentage,
                         colorOverride: vehicle.allowed > 0 ? nil : Color.accentColor) {
            VStack {
              Text("Estimate")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.subText)
              Text("\(extendedInfo.normalPredicatedMileage)")
                .lineLimit(1)
                .font(.system(size: 30, weight: .bold, design: .rounded))
              Text(lengthUnit.longName)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.subText)
            }
          }.frame(width: 150.0, height: 150.0)
            .padding(40.0)
          
          
          Spacer()
        }
        .listRowSeparator(.hidden)
        .frame(height: 240)
      }
      
      
      // Actions
      Section {
        Button(action: { self.activeSheet = .readingCreation }) {
          Label("Add odometer reading", systemImage: "plus")
        }.listRowSeparator(.hidden)
      }
      
      // Basic info
      Section {
        Grid {
          GridRow {
            InfoPanel(title: Text("Current mileage"), unit: Text(lengthUnit.shortFor), value: Text(String(extendedInfo.currentMileage)))
              .cardLike()
            InfoPanel(title: Text("Unused mileage"), unit: Text(lengthUnit.shortFor), value: Text(String(extendedInfo.leftMileage)))
              .cardLike()
          }
          
          GridRow {
            InfoPanel(title: Text("Daily average"), unit: Text(lengthUnit.shortFor), value: Text(String(extendedInfo.mileagePerDay)))
              .cardLike()
            InfoPanel(title: Text("Monthly average"), unit: Text(lengthUnit.shortFor), value: Text(String(extendedInfo.mileagePerMonth)))
              .cardLike()
          }
          
          
          if let excessMileage = extendedInfo.excessMileage, let excessCharge = extendedInfo.excessCharge {
            if vehicle.allowed > 0 {
              GridRow {
                InfoPanel(title: Text("Excess mileage"), unit: Text(lengthUnit.shortFor), value: Text(String(excessMileage)))
                  .cardLike()
                InfoPanel(title: Text("Excess charge"), unit: Text(currency.rawValue), value: Text(String(excessCharge)))
                  .cardLike()
              }
            }
          }
        }.listRowSeparator(.hidden)
      }
      
      // Graph
      Section {
        Picker("Graph type", selection: $graphType) {
          Text("Monthly").tag(GraphType.monthly)
          Text("Last 30 days").tag(GraphType.daily)
        }
        .pickerStyle(SegmentedPickerStyle())
        .listRowSeparator(.hidden)
        if graphType == .monthly {
          LineGraph(data: extendedInfo.monthlyMileageDataForLineChart)
            .listRowInsets(EdgeInsets(top: 0, leading: -20, bottom: 0, trailing: -20))
            .listRowSeparator(.hidden)
        } else if graphType == .daily {
          BarGraph(data: extendedInfo.dailyMileageDataForLineChart.suffix(30))
        }
      }.padding(.vertical)
      
      // Banner ad
      if !purchaseManager.unlockPro {
        Section {
          BannerAd().listRowSeparator(.hidden)
        }
      }
      
      // More/other info
      Section {
        if vehicle.allowed > 0 {
          MoreInfoView(question: Text("What should my odometer read?"),
                       answer: Text("Your odometer should read less than \(String(extendedInfo.mileageShouldLessThan))."),
                       more: Text("To calculate the result, we take the number of miles you're allowed to drive each day according to your lease agreement and multiply it by the number of days that have passed since the lease started. Then we add the starting mileage to that total."))
        }
        
        MoreInfoView(question: Text("How far can I drive today?"),
                     answer: vehicle.allowed == 0 ?
                     Text("You can drive as far as you want because you did not set the mileage allowed.") :
                      Text("You can drive up to \(String(extendedInfo.maxDriveToday)) \(lengthUnit.longName.toString()) today and still be on track."),
                     more: Text("To determine if the car has exceeded the maximum mileage allowed, we subtract the current mileage from the maximum allowable mileage."))
        
        MoreInfoView(question: Text("When does my lease expire?"),
                     answer: extendedInfo.isExpired ?
                     Text("Congratulations, your lease is expired.") :
                      Text("You have \(String(extendedInfo.leaseLeft)) months left. Keep up the work!"),
                     more: Text("To calculate the remaining lease duration, we subtract the number of months that have passed since the lease started from the total length of the lease."))
      } footer: {
        Text("The information provided is for predication purposes only and should not be construed as actual numbers. While we make every effort to ensure the accuracy of the information presented, we cannot guarantee that it is free from errors or omissions. We are not liable for any damages or losses that may arise from the use of this information.")
          .font(.system(size: 12.0))
          .foregroundColor(.subText)
          .listRowSeparator(.hidden)
      }
    }
    .listStyle(.plain)
    .navigationBarTitle(vehicle.name ?? "",
                        displayMode: .inline)
    .toolbar {
      ToolbarItem(placement: .secondaryAction) {
        Button(action: { activeSheet = .vehicleEdit }) {
          Label("Vehicle Setting", systemImage: "gearshape")
        }
        
      }
      ToolbarItem(placement: .secondaryAction) {
        NavigationLink(destination: ReadingList(vehicle: vehicle).navigationBarTitle("Odometer History")) {
          Label("Odometer History", systemImage: "calendar.badge.clock")
        }
      }
    }
    .sheet(item: $activeSheet) { item in
      switch item {
        case .readingCreation:
          EditReadingView(vehicle: vehicle,
                          onDismiss: handleSheetDismiss)
            .environment(\.managedObjectContext, viewContext)
            .withErrorHandler()
        case .vehicleEdit:
          EditVehicleView(vehicle: vehicle,
                          onDismiss: handleSheetDismiss,
                          onDeletion: handleVehicleDeletion)
            .environment(\.managedObjectContext, viewContext)
            .withErrorHandler()
      }
    }
    .onAppear {
      Logger.shared.vehiclePageView()
      SwiftRater.check()
    }
  }
  
  private func handleSheetDismiss() {
    activeSheet = nil
  }
  
  private func handleVehicleDeletion() {
    self.presentationMode.wrappedValue.dismiss()
  }
}

