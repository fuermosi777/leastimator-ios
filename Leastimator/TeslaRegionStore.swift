//
//  TeslaRegionStore.swift
//  Leastimator
//
//  Caches the Tesla Fleet API base domain per connection. Tesla's Fleet API is
//  regionally sharded: a user's vehicles live in one region (NA, EU, ...), and
//  calling the wrong regional host returns HTTP 421 "user out of region". We
//  discover the correct host once (via /api/1/users/region, or by parsing a 421
//  body) and remember it so later calls go straight to the right region.
//
//  The base domain is not sensitive (just a hostname), so UserDefaults is fine —
//  no need to bundle it into the Keychain token blob.
//

import Foundation

enum TeslaRegionStore {
    static let defaultDomain = "fleet-api.prd.na.vn.cloud.tesla.com"

    private static let keyPrefix = "tesla.baseDomain."

    static func domain(for connectionId: String) -> String {
        UserDefaults.standard.string(forKey: keyPrefix + connectionId) ?? defaultDomain
    }

    static func setDomain(_ domain: String, for connectionId: String) {
        UserDefaults.standard.set(domain, forKey: keyPrefix + connectionId)
    }

    static func clear(for connectionId: String) {
        UserDefaults.standard.removeObject(forKey: keyPrefix + connectionId)
    }

    /// Extracts a Fleet API host from a 421 error body, e.g.
    /// `{"error":"user out of region, use base URL: https://fleet-api.prd.eu.vn.cloud.tesla.com, see ..."}`
    /// Returns the bare host (no scheme/path) suitable for `setDomain`.
    static func parseRegionHost(fromErrorBody body: String) -> String? {
        let marker = "https://fleet-api.prd."
        guard let range = body.range(of: marker) else { return nil }
        // Host runs until a comma, quote, whitespace, or slash after the scheme.
        let afterScheme = body[range.upperBound...]
        let hostTail = afterScheme.prefix { ch in
            ch != "," && ch != "\"" && ch != " " && ch != "/" && ch != "\n" && ch != "\\"
        }
        guard !hostTail.isEmpty else { return nil }
        return "fleet-api.prd." + hostTail
    }
}
