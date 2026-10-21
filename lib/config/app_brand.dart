import 'package:showglobe_core/showglobe_core.dart' show AppBrand;

import 'theme.dart';

/// Name, colour and identifiers of this app inside the Showglobe/Japanaut series.
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
