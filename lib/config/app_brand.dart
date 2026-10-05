import 'package:japanaut_kit/japanaut_kit.dart';

import 'theme.dart';

/// Name, colour and identifiers of this app inside the Japanaut series.
/// Changing the display name only requires editing [AppBrand.suffix] here.
final tripBrand = AppBrand(
  suffix: 'Trip',
  slug: 'trip',
  packageName: 'com.yourwish.japanexplorer',
  tagline: 'Discover Japan like a local',
  primaryColor: AppColors.primary,
  supportEmail: 'petitworksdev@gmail.com',
);

/// Shared privacy policy of Petit Works Apps (Google Sites).
const privacyPolicyUrl =
    'https://sites.google.com/view/yourwishapps/privacy-policy';

/// Store page used in share messages (no own domain).
const playStoreUrl =
    'https://play.google.com/store/apps/details?id=com.yourwish.japanexplorer';
