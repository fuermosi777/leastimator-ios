//
//  TeslaSyncService.swift
//  Leastimator
//

import Foundation
import CoreData

class TeslaSyncService {
    static let shared = TeslaSyncService()
    
    private init() {}
    
    @MainActor
    func performSync(context: NSManagedObjectContext) async {
        let fetchRequest = NSFetchRequest<Vehicle>(entityName: "Vehicle")
        fetchRequest.predicate = NSPredicate(format: "teslaConnectionId != nil AND teslaVehicleId != nil AND (removed == nil OR removed == false)")
        
        guard let vehicles = try? context.fetch(fetchRequest), !vehicles.isEmpty else {
            return
        }
        
        for vehicle in vehicles {
            guard let connId = vehicle.teslaConnectionId, let vid = vehicle.teslaVehicleId else { continue }
            
            // Skip if no token on this device
            if KeychainHelper.shared.load(for: connId) == nil {
                continue
            }
            
            let service = TeslaService(connectionId: connId)
            
            do {
                let teslaVehicles = try await service.getVehicles()
                if let targetTesla = teslaVehicles.first(where: { $0.id == vid }) {
                    // Only fetch odometer if vehicle is already awake/online to prevent phantom battery drain
                    if targetTesla.state.lowercased() == "online" {
                        let data = try await service.getVehicleData(vehicleId: vid)
                        let odo = data.vehicle_state.odometer
                        
                        var finalValue = odo
                        if vehicle.lengthUnit == LengthUnit.Metric.rawValue {
                            finalValue = odo * 1.60934
                        }
                        
                        // Check if we should add this reading based on the threshold
                        if self.shouldAddReading(vehicle: vehicle, newValue: finalValue) {
                            let reading = OdoReading(context: context)
                            reading.value = Int64(finalValue)
                            reading.date = Date()
                            reading.vehicle = vehicle
                            
                            try? context.save()
                        }
                    }
                }
            } catch {
                print("Failed to sync Tesla vehicle \(vid) in background: \(error)")
                Logger.shared.teslaSyncError(vehicleId: vid, error)
            }
        }
    }
    
    func shouldAddReading(vehicle: Vehicle, newValue: Double) -> Bool {
        var lastOdo: Double = Double(vehicle.starting)
        var lastReadingDate = Date.distantPast
        
        if let readingsSet = vehicle.readings as? Set<OdoReading> {
            if let maxReading = readingsSet.max(by: { ($0.date ?? Date.distantPast) < ($1.date ?? Date.distantPast) }) {
                lastOdo = Double(maxReading.value)
                lastReadingDate = maxReading.date ?? Date.distantPast
            }
        }
        
        let diff = newValue - lastOdo
        var threshold: Double = 1.0
        
        // If there is a reading from today, we only add if it's >= 5 miles difference
        if Calendar.current.isDateInToday(lastReadingDate) {
            let milesThreshold: Double = 5.0
            if vehicle.lengthUnit == LengthUnit.Metric.rawValue {
                threshold = milesThreshold * 1.60934
            } else {
                threshold = milesThreshold
            }
        }
        
        return diff >= threshold
    }
}
