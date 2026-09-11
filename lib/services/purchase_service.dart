import 'dart:async';
import 'dart:io' show Platform;
import 'package:purchases_flutter/purchases_flutter.dart';

// ── RevenueCat API keys ───────────────────────────────────────────────────────
// Replace these with your actual keys from app.revenuecat.com
const _kAndroidApiKey = 'YOUR_REVENUECAT_PUBLIC_KEY_ANDROID';
const _kAppleApiKey   = 'YOUR_REVENUECAT_PUBLIC_KEY_APPLE';

/// The entitlement identifier configured in the RevenueCat dashboard
const kPremiumEntitlement = 'premium';

// ── Service ───────────────────────────────────────────────────────────────────

class PurchaseService {
  PurchaseService._();

  bool _configured = false;

  // RevenueCat 10.x uses a listener pattern instead of a Stream.
  // We bridge it to a broadcast StreamController for Riverpod compatibility.
  final _customerInfoController =
      StreamController<CustomerInfo>.broadcast();

  /// Emits whenever the user's entitlements change (purchase, restore, expiry).
  Stream<CustomerInfo> get customerInfoStream => _customerInfoController.stream;

  /// Configure the RevenueCat SDK once at app start (before sign-in).
  /// Uses an anonymous user ID until [loginUser] is called.
  Future<void> configure() async {
    if (_configured) return;
    _configured = true;
    await Purchases.setLogLevel(LogLevel.debug);
    final key = Platform.isAndroid ? _kAndroidApiKey : _kAppleApiKey;
    await Purchases.configure(PurchasesConfiguration(key));
    Purchases.addCustomerInfoUpdateListener((info) {
      _customerInfoController.add(info);
    });
  }

  /// Identify the signed-in user so their entitlements transfer across devices.
  Future<void> loginUser(String userId) async {
    try {
      await Purchases.logIn(userId);
    } catch (_) {}
  }

  /// Reset to a new anonymous user when the current user signs out.
  Future<void> logoutUser() async {
    try {
      await Purchases.logOut();
    } catch (_) {}
  }

  // ── Entitlement helpers ─────────────────────────────────────────────────────

  Future<CustomerInfo> getCustomerInfo() => Purchases.getCustomerInfo();

  bool isPremium(CustomerInfo info) =>
      info.entitlements.active.containsKey(kPremiumEntitlement);

  // ── Offerings / packages ────────────────────────────────────────────────────

  /// Returns the packages in the current RevenueCat offering.
  /// Empty list if no network or not configured.
  Future<List<Package>> getPackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? [];
    } catch (_) {
      return [];
    }
  }

  // ── Transactions ────────────────────────────────────────────────────────────

  /// Returns the updated [CustomerInfo] on success, null if the user cancelled.
  /// RevenueCat 10.x: purchasePackage returns PurchaseResult; extract customerInfo.
  Future<CustomerInfo?> purchase(Package package) async {
    try {
      final result = await Purchases.purchasePackage(package);
      return result.customerInfo;
    } on PurchasesError catch (e) {
      if (e.code == PurchasesErrorCode.purchaseCancelledError) return null;
      rethrow;
    }
  }

  /// Restore past purchases — required by App Store / Play Store guidelines.
  Future<CustomerInfo> restorePurchases() => Purchases.restorePurchases();
}

/// Singleton instance used across the app
final purchaseService = PurchaseService._();
