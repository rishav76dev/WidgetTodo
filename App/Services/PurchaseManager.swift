import Foundation
import Observation
import os
import RevenueCat
import TodoKit

/// RevenueCat wrapper. Without a real API key the app stays in free mode and every call is a no-op.
@MainActor @Observable
final class PurchaseManager {
    var isConfigured = false
    /// Premium comes from an auto-renewing subscription (so Manage Subscription applies), not the lifetime unlock.
    private(set) var hasActiveSubscription = false

    @ObservationIgnored private var listener: Task<Void, Never>?
    @ObservationIgnored private let logger = Logger(subsystem: "ai.shavastudios.todo1", category: "purchases")

    func configure() {
        guard !isConfigured else { return }
        let key = (Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, !key.contains("REPLACE_ME") else {
            logger.notice("RevenueCatAPIKey is not set; running in free mode")
            return
        }
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: key)
        isConfigured = true
    }

    /// Applies every customer-info change (purchase, renewal, expiry) as it arrives. Safe to call repeatedly.
    func start(model: AppModel) {
        guard isConfigured, listener == nil else { return }
        listener = Task { [weak self] in
            for await info in Purchases.shared.customerInfoStream {
                guard let self else { return }
                await self.apply(info, model: model)
            }
        }
    }

    /// Fetches customer info and offering metadata. On failure the last stored state is kept.
    func refresh(model: AppModel) async {
        guard isConfigured else { return }
        start(model: model)
        do {
            let info = try await Purchases.shared.customerInfo()
            await apply(info, model: model)
        } catch {
            logger.error("Customer info refresh failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Maps `info` and the current offering's metadata to an `EntitlementState`.
    /// If offerings can't be fetched, the stored free-theme count and order are kept.
    func apply(_ info: CustomerInfo, model: AppModel) async {
        let isPremium = info.entitlements[AppConstants.entitlementID]?.isActive == true
        hasActiveSubscription = isPremium && !info.activeSubscriptions.isEmpty
        let state: EntitlementState
        do {
            let offerings = try await Purchases.shared.offerings()
            state = .from(isPremium: isPremium, offeringMetadata: offerings.current?.metadata ?? [:])
        } catch {
            logger.error("Offerings fetch failed: \(error.localizedDescription, privacy: .public)")
            var kept = model.entitlements
            kept.isPremium = isPremium
            state = kept
        }
        model.applyEntitlements(state)
    }

    /// Restores purchases for the current Apple ID and returns a message for the user.
    func restore(model: AppModel) async -> String {
        guard isConfigured else { return "Purchases are unavailable right now. Please try again later." }
        do {
            let info = try await Purchases.shared.restorePurchases()
            await apply(info, model: model)
            return info.entitlements[AppConstants.entitlementID]?.isActive == true
                ? "Premium restored. All themes are unlocked."
                : "No previous purchases were found for this Apple ID."
        } catch {
            return "Restore failed: \(error.localizedDescription)"
        }
    }
}
