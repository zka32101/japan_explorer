import 'package:showglobe_core/showglobe_core.dart'
    show AppBrand, kGlobalSeriesName;

import 'theme.dart';

/// Name, colour and identifiers of this app inside the Showglobe series
/// (display name: "Showglobe Japan"). The series name comes from
/// [AppBrand.series]; the country/app part from [AppBrand.suffix].
/// [AppBrand.slug] stays 'trip' because it is the existing notification
/// channel id and storage-key prefix.
final tripBrand = AppBrand(
  series: kGlobalSeriesName,
  suffix: 'Japan',
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
