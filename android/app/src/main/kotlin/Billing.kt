package com.widgettodo

import android.app.Activity
import android.app.AlertDialog
import android.content.Context
import com.revenuecat.purchases.*
import java.time.Instant

object Billing {
    private var started = false
    fun start(context: Context, changed: () -> Unit) {
        if (BuildConfig.REVENUECAT_API_KEY.isBlank()) return
        if (!started) {
            Purchases.configure(PurchasesConfiguration.Builder(context.applicationContext, BuildConfig.REVENUECAT_API_KEY).build())
            started = true
        }
        Purchases.sharedInstance.getCustomerInfoWith(onError = {}, onSuccess = { cache(context, it); changed() })
    }
    private fun cache(context: Context, info: CustomerInfo) {
        val entitlement = info.entitlements["premium"]
        val expiry = if (entitlement?.isActive == true) entitlement.expirationDate?.time ?: Long.MAX_VALUE else 0L
        context.getSharedPreferences("billing", 0).edit().putLong("premiumUntil", expiry).apply()
        TodoWidget.refresh(context)
    }
    fun unlocked(context: Context, id: String): Boolean = id in listOf("paper", "midnight", "mono-mint") ||
        context.getSharedPreferences("billing", 0).getLong("premiumUntil", 0L) > Instant.now().toEpochMilli()
    fun paywall(activity: Activity, changed: () -> Unit) {
        if (!started) {
            AlertDialog.Builder(activity).setTitle("Premium").setMessage("Premium unlocks all 12 themes. Google Play purchases will be available once the Android store is configured. The three free themes are ready to use.").setPositiveButton("OK", null).show()
            return
        }
        Purchases.sharedInstance.getOfferingsWith(onError = { message(activity, it.message) }, onSuccess = { offerings ->
            val packages = offerings.current?.availablePackages.orEmpty()
            if (packages.isEmpty()) { message(activity, "No products are available from Google Play yet."); return@getOfferingsWith }
            AlertDialog.Builder(activity).setTitle("Todo1 Premium").setItems(packages.map { "${it.product.title} · ${it.product.price.formatted}" }.toTypedArray()) { _, which ->
                Purchases.sharedInstance.purchaseWith(PurchaseParams.Builder(activity, packages[which]).build(),
                    onError = { error, cancelled -> if (!cancelled) message(activity, error.message) },
                    onSuccess = { _, info -> cache(activity, info); changed() })
            }.setNegativeButton("Cancel", null).show()
        })
    }
    fun restore(activity: Activity, changed: () -> Unit) {
        if (!started) { message(activity, "Google Play purchases are not configured yet."); return }
        Purchases.sharedInstance.restorePurchasesWith(onError = { message(activity, it.message) }, onSuccess = {
            cache(activity, it); changed(); message(activity, if (it.entitlements["premium"]?.isActive == true) "Premium restored." else "No active Premium purchase found.")
        })
    }
    private fun message(activity: Activity, value: String) { AlertDialog.Builder(activity).setMessage(value).setPositiveButton("OK", null).show() }
}
