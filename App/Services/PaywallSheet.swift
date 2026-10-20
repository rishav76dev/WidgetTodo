import RevenueCat
import RevenueCatUI
import SwiftUI
import TodoKit

/// The RevenueCat paywall for the current offering, or a fallback when purchases aren't configured.
struct PaywallSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(PurchaseManager.self) private var purchases
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if purchases.isConfigured {
            PaywallView(displayCloseButton: true)
                .onPurchaseCompleted { customerInfo in
                    finish(with: customerInfo, dismissing: true)
                }
                .onRestoreCompleted { customerInfo in
                    // With nothing to restore, stay on the paywall; RevenueCatUI tells the user.
                    let restored = customerInfo.entitlements[AppConstants.entitlementID]?.isActive == true
                    finish(with: customerInfo, dismissing: restored)
                }
        } else {
            NavigationStack {
                ContentUnavailableView {
                    Label("Purchases unavailable right now", systemImage: "cart.badge.questionmark")
                } description: {
                    Text("Please check your connection and try again later. Your free themes keep working.")
                }
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Close") { dismiss() }
                    }
                }
            }
        }
    }

    private func finish(with info: CustomerInfo, dismissing: Bool) {
        Task {
            await purchases.apply(info, model: model)
            if dismissing { dismiss() }
        }
    }
}
