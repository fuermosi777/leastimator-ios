//
//  VehiclePresentation.swift
//  Leastimator
//
//  Created by Hao Liu on 3/28/21.
//

import SwiftUI
import SwiftRater
import Charts

struct InfoPanel: View {
  var title: Text
  var unit: Text
  var value: Text
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      title
        .foregroundColor(.subText)
      HStack(alignment: .lastTextBaseline) {
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
    .listRowBackground(Color.clear)
  }
}

struct VehiclePresentation: View {
  @Environment(\.managedObjectContext) private var viewContext
  @EnvironmentObject private var purchaseManager: PurchaseManager
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  @AppStorage("showMileageVariance") private var showMileageVariance = true
  
  // Add ObservedObject make sure it gets updated data.
  @ObservedObject var vehicle: Vehicle
  
  @State private var dashboardIndex = 0
  
  @State var chartTapValue: Int? = 0
  
  @State var graphType: GraphType = .monthly
  
  @State private var showAddReadingSheet = false
  
  enum GraphType {
    case monthly, daily
  }
  
  init(vehicle: Vehicle) {
    self.vehicle = vehicle
  }
  
  var extendedInfo: ExtendedVehicleInfo {
    return Compute(vehicle)
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
      return min(Float(up / down), 1.0)
    }
    return 1.0
  }
  
  let linearGradient = LinearGradient(
    gradient: Gradient (
      colors: [
        .accentColor.opacity(0.6),
        .accentColor.opacity(0.4),
        .accentColor.opacity(0.0),
      ]
    ),
    startPoint: .top, endPoint: .bottom)
  
  
  var body: some View {
    List {
      Section {
        ZStack {
          VStack(alignment: .leading) {
            HStack(alignment: .lastTextBaseline) {
              Text("\(extendedInfo.normalPredicatedMileage)")
                .lineLimit(1)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.mainText)
              if let mileageVariance = extendedInfo.mileageVariance, showMileageVariance {
                Text("\(mileageVariance < 0 ? "-" : "+")\(abs(mileageVariance))")
                  .lineLimit(1)
                  .font(.system(size: 14, weight: .bold, design: .rounded))
                  .foregroundColor(mileageVariance < 0 ? Color.green : Color.red)
              }
              Text(lengthUnit.longName)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.mainText)
            }
            Text("Estimated mileage")
              .font(.system(size: 14, design: .rounded))
              .foregroundColor(.subText)
            ProgressBar(progress: progressPercentage,
                        colorOverride: vehicle.allowed > 0 ? nil : Color.accentColor,
                        length: 200.0)
          }
          HStack {
            Spacer()
            VehicleImage(data: vehicle.image, size: 100.0)
          }
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
      }
      
      // Actions
      Section {
        Button { showAddReadingSheet.toggle() } label: {
          Label("Add odometer reading", systemImage: "plus.circle.fill")
        }
        .padding(.vertical)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
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
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
      }
      
      // Graph
      Section {
        Chart {
          ForEach(extendedInfo.monthlyMileageDataForLineChart) { point in
            LineMark(
              x: .value("Month", point.label),
              y: .value("Value", point.value)
            )
            
            if point.label == extendedInfo.monthlyMileageDataForLineChart.last?.label {
              PointMark(
                x: .value("Month", point.label),
                y: .value("Value", point.value)
              )
              .annotation {
                Text(point.value.decimalString())
                  .font(.caption)
                  .foregroundStyle(Color.mainText)
              }
            } else if point.value > 0 {
              PointMark(
                x: .value("Month", point.label),
                y: .value("Value", point.value)
              )
            }
            
            AreaMark(
              x: .value("Date", point.label),
              y: .value("Value", point.value))
            .foregroundStyle(linearGradient)
          }
          
          if vehicle.allowed > 0 {
            RuleMark(y: .value("Should be less than", Double(extendedInfo.mileageShouldLessThan)))
              .foregroundStyle(.red)
          }
        }
        .chartYAxis {
          AxisMarks { _ in
            AxisGridLine()
            AxisTick()
            AxisValueLabel()
          }
        }
        .chartYScale(domain: 0...max(extendedInfo.currentMileage, extendedInfo.mileageShouldLessThan) + 2000)
        .background(.clear)
        .chartScrollableAxes(.horizontal)
        .chartScrollPosition(initialX: extendedInfo.monthlyMileageDataForLineChart.scrollStarter())
        .chartXVisibleDomain(length: 5)
        .frame(height: 200.0)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        
      }.padding(.vertical)
      
      // Banner ad
      if !purchaseManager.unlockPro {
        Section {
          BannerAd()
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
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
        Text("disclaimer")
          .font(.system(size: 12.0))
          .foregroundColor(.subText)
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
      }
    }
    .scrollContentBackground(.hidden)
    .listStyle(.plain)
    .sheet(isPresented: $showAddReadingSheet) {
      EditReadingView(vehicle: vehicle)
        .withErrorHandler()
    }
    .onAppear {
      Logger.shared.vehiclePageView()
      SwiftRater.check()
    }
  }
}

