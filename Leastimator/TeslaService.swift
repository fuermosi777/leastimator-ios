//
//  TeslaService.swift
//  Leastimator
//

import Foundation

struct TeslaVehicleListResponse: Codable {
    let response: [TeslaVehicle]
}

struct TeslaVehicle: Codable, Identifiable {
    let id_s: String // String ID is safer for JavaScript / large int incompatibilities
    let vin: String
    let display_name: String?
    let state: String
    
    var id: String { id_s }
    
    var safeDisplayName: String {
        if let name = display_name, !name.isEmpty {
            return name
        }
        return "Tesla (\(vin.suffix(6)))"
    }
}

struct TeslaVehicleDataResponse: Codable {
    let response: TeslaVehicleData
}

struct TeslaVehicleData: Codable {
    let vehicle_state: TeslaVehicleState
}

struct TeslaVehicleState: Codable {
    let odometer: Double
}

class TeslaService {
    let connectionId: String
    let baseDomain: String
    
    // IMPORTANT: Make sure this domain matches your registered Fleet API region
    // North America: "fleet-api.prd.na.vn.cloud.tesla.com"
    // Europe: "fleet-api.prd.eu.vn.cloud.tesla.com"
    // China: "fleet-api.prd.cn.vn.cloud.tesla.com"
    init(connectionId: String, baseDomain: String = "fleet-api.prd.na.vn.cloud.tesla.com") {
        self.connectionId = connectionId
        self.baseDomain = baseDomain
    }
    
    private func getValidToken() async throws -> String {
        guard let tokens = KeychainHelper.shared.load(for: connectionId) else {
            throw TeslaAuthError.missingCode // Treat as missing token
        }
        
        if tokens.isExpired {
            // refresh token
            let newTokens = try await TeslaAuthManager.shared.refreshTokens(refreshToken: tokens.refreshToken, connectionId: connectionId)
            KeychainHelper.shared.save(newTokens, for: connectionId)
            return newTokens.accessToken
        }
        
        return tokens.accessToken
    }
    
    func getVehicles() async throws -> [TeslaVehicle] {
        let token = try await getValidToken()
        guard let url = URL(string: "https://\(baseDomain)/api/1/vehicles") else {
            throw TeslaAuthError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw TeslaAuthError.apiError("Failed to fetch vehicles (\(response)): \(body)")
        }
        
        let listResponse = try JSONDecoder().decode(TeslaVehicleListResponse.self, from: data)
        return listResponse.response
    }
    
    func getVehicleData(vehicleId: String) async throws -> TeslaVehicleData {
        let token = try await getValidToken()
        guard let url = URL(string: "https://\(baseDomain)/api/1/vehicles/\(vehicleId)/vehicle_data") else {
            throw TeslaAuthError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw TeslaAuthError.apiError("Failed to fetch vehicle data: \(body)")
        }
        
        let dataResponse = try JSONDecoder().decode(TeslaVehicleDataResponse.self, from: data)
        return dataResponse.response
    }
    
    func wakeUp(vehicleId: String) async throws {
        let token = try await getValidToken()
        guard let url = URL(string: "https://\(baseDomain)/api/1/vehicles/\(vehicleId)/wake_up") else {
            throw TeslaAuthError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw TeslaAuthError.apiError("Failed to wake up vehicle")
        }
    }
}
