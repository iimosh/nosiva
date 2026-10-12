import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../l10n/app_localizations.dart';

enum LocationFailure { servicesOff, permissionDenied, permissionBlocked, cityNotFound }

/// Why the city couldn't be found. Screens turn this into a translated
/// message with [locationErrorMessage].
class LocationException implements Exception {
  const LocationException(this.reason);
  final LocationFailure reason;
  @override
  String toString() => 'LocationException(${reason.name})';
}

class LocationService {
  const LocationService();

  Future<String> currentCity() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(LocationFailure.servicesOff);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(LocationFailure.permissionDenied);
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(LocationFailure.permissionBlocked);
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 15),
      ),
    );

    final placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    if (placemarks.isEmpty) {
      throw const LocationException(LocationFailure.cityNotFound);
    }

    final place = placemarks.first;
    final city = _firstNonEmpty([
      place.locality,
      place.subAdministrativeArea,
      place.administrativeArea,
    ]);
    if (city.isEmpty) {
      throw const LocationException(LocationFailure.cityNotFound);
    }
    return city;
  }

  static String _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.isNotEmpty) return v;
    }
    return '';
  }
}

/// A translated, user-friendly message for any error from [currentCity] —
/// including timeouts and network errors, which never show their raw text.
String locationErrorMessage(AppLocalizations l10n, Object error) {
  if (error is! LocationException) return l10n.locationUnavailable;
  return switch (error.reason) {
    LocationFailure.servicesOff => l10n.locationServicesOff,
    LocationFailure.permissionDenied => l10n.locationPermissionDenied,
    LocationFailure.permissionBlocked => l10n.locationPermissionBlocked,
    LocationFailure.cityNotFound => l10n.locationCityNotFound,
  };
}

final locationServiceProvider =
    Provider<LocationService>((ref) => const LocationService());
