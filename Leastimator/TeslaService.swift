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

struct TeslaRegionResponse: Codable {
    struct Region: Codable {
        let fleet_api_base_url: String
    }
    let response: Region
}

class TeslaService {
    let connectionId: String

    // The Fleet API is regionally sharded. We start from the cached region for
    // this connection (NA default on first use) and self-correct on a 421.
    private var baseDomain: String

    init(connectionId: String, baseDomain: String? = nil) {
        self.connectionId = connectionId
        self.baseDomain = baseDomain ?? TeslaRegionStore.domain(for: connectionId)
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

    // MARK: - Region-aware request

    /// Performs an authenticated Fleet API request against the current region.
    /// On HTTP 421 ("user out of region"), it switches to the region named in
    /// the error body, caches it for future calls, and retries once.
    private func send(
        op: String,
        method: String,
        path: String,
        allowRegionRetry: Bool = true
    ) async throws -> Data {
        let token = try await getValidToken()
        guard let url = URL(string: "https://\(baseDomain)\(path)") else {
            throw TeslaAuthError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1

        if status == 200 {
            return data
        }

        let body = String(data: data, encoding: .utf8) ?? ""

        // 421: wrong region. Adopt the region Tesla tells us to use and retry.
        if status == 421, allowRegionRetry,
           let newDomain = TeslaRegionStore.parseRegionHost(fromErrorBody: body),
           newDomain != baseDomain {
            baseDomain = newDomain
            TeslaRegionStore.setDomain(newDomain, for: connectionId)
            return try await send(op: op, method: method, path: path, allowRegionRetry: false)
        }

        let error = TeslaAuthError.apiError("\(op) \(baseDomain) HTTP \(status): \(body)")
        Logger.shared.teslaAPIError(op, error)
        throw error
    }

    /// Discovers and caches the correct region for this connection via
    /// /api/1/users/region. Cheap, region-agnostic, and avoids a wasted 421 on
    /// the first real call. Failures are non-fatal — the 421 retry still covers us.
    func resolveRegionIfNeeded() async {
        let data = try? await send(op: "region", method: "GET", path: "/api/1/users/region", allowRegionRetry: false)
        guard let data,
              let region = try? JSONDecoder().decode(TeslaRegionResponse.self, from: data),
              let host = URL(string: region.response.fleet_api_base_url)?.host else {
            return
        }
        baseDomain = host
        TeslaRegionStore.setDomain(host, for: connectionId)
    }

    func getVehicles() async throws -> [TeslaVehicle] {
        let data = try await send(op: "getVehicles", method: "GET", path: "/api/1/vehicles")
        return try JSONDecoder().decode(TeslaVehicleListResponse.self, from: data).response
    }

    func getVehicleData(vehicleId: String) async throws -> TeslaVehicleData {
        let data = try await send(op: "getVehicleData", method: "GET", path: "/api/1/vehicles/\(vehicleId)/vehicle_data")
        return try JSONDecoder().decode(TeslaVehicleDataResponse.self, from: data).response
    }

    func wakeUp(vehicleId: String) async throws {
        _ = try await send(op: "wakeUp", method: "POST", path: "/api/1/vehicles/\(vehicleId)/wake_up")
    }
}
