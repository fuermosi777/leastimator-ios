//
//  SheetStore.swift
//  Leastimator
//
//  Created by Hao Liu on 5/14/21.
//

import Foundation

class SheetStore: ObservableObject {
  enum Sheet: Identifiable {
    case addReading,
         vehicleCreation
    var id: Int { hashValue }
  }
  
  @Published var activeSheet: Sheet?
}
