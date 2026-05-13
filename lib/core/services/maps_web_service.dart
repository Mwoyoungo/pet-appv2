import 'dart:async';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Web-specific Google Maps service using JS API (avoids CORS)
/// This bridges to maps_web_service.js which uses the Google Maps JS API
class MapsWebService {
  static bool get isSupported => kIsWeb;

  /// Get autocomplete suggestions
  static Future<List<Map<String, String>>> getSuggestions(String input) async {
    if (!isSupported) return [];

    final completer = Completer<List<Map<String, String>>>();

    try {
      final service = js.context['MapsWebService'];

      if (service == null) {
        debugPrint('[MapsWebService] JS service not found');
        return [];
      }

      // Create a JS callback function
      final callback = js.allowInterop((dynamic results) {
        final suggestions = <Map<String, String>>[];
        if (results is List) {
          for (var item in results) {
            // Convert JsObject to Dart Map
            final jsItem = js.JsObject.fromBrowserObject(item as js.JsObject);
            final desc = jsItem['description'] as String?;
            final placeId = jsItem['placeId'] as String?;
            if (desc != null && placeId != null) {
              suggestions.add({'description': desc, 'placeId': placeId});
            }
          }
        }
        if (!completer.isCompleted) {
          completer.complete(suggestions);
        }
      });

      service.callMethod('getSuggestions', [input, callback]);

      // Timeout after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (!completer.isCompleted) {
          completer.complete([]);
        }
      });
    } catch (e) {
      debugPrint('[MapsWebService] Error: $e');
      return [];
    }

    return completer.future;
  }

  /// Get place details (lat/lng)
  static Future<LatLng?> getPlaceDetails(String placeId) async {
    if (!isSupported) return null;

    final completer = Completer<LatLng?>();

    try {
      final service = js.context['MapsWebService'];

      if (service == null) return null;

      final callback = js.allowInterop((dynamic result) {
        if (result != null) {
          final jsResult = js.JsObject.fromBrowserObject(result as js.JsObject);
          final lat = jsResult['lat'] as num?;
          final lng = jsResult['lng'] as num?;
          if (lat != null && lng != null) {
            completer.complete(LatLng(lat.toDouble(), lng.toDouble()));
            return;
          }
        }
        completer.complete(null);
      });

      service.callMethod('getPlaceDetails', [placeId, callback]);

      Future.delayed(const Duration(seconds: 2), () {
        if (!completer.isCompleted) completer.complete(null);
      });
    } catch (e) {
      debugPrint('[MapsWebService] Place details error: $e');
      return null;
    }

    return completer.future;
  }

  /// Get directions
  static Future<Map<String, dynamic>?> getDirections(
    LatLng origin,
    LatLng destination,
  ) async {
    if (!isSupported) return null;

    final completer = Completer<Map<String, dynamic>?>();

    try {
      final service = js.context['MapsWebService'];

      if (service == null) return null;

      final callback = js.allowInterop((dynamic result) {
        if (result != null) {
          final jsResult = js.JsObject.fromBrowserObject(result as js.JsObject);
          final distanceText = jsResult['distanceText'] as String?;
          final distanceValue = jsResult['distanceValue'] as num?;
          final durationText = jsResult['durationText'] as String?;
          final pointsList = jsResult['points'];

          if (distanceText != null &&
              pointsList != null &&
              pointsList is List) {
            final points = <LatLng>[];
            for (var p in pointsList) {
              final point = js.JsObject.fromBrowserObject(p as js.JsObject);
              final lat = point['lat'] as num?;
              final lng = point['lng'] as num?;
              if (lat != null && lng != null) {
                points.add(LatLng(lat.toDouble(), lng.toDouble()));
              }
            }

            completer.complete({
              'distanceText': distanceText,
              'distanceValue': distanceValue?.toDouble() ?? 0.0,
              'durationText': durationText ?? '',
              'points': points,
            });
            return;
          }
        }
        completer.complete(null);
      });

      service.callMethod('getDirections', [
        origin.latitude,
        origin.longitude,
        destination.latitude,
        destination.longitude,
        callback,
      ]);

      Future.delayed(const Duration(seconds: 3), () {
        if (!completer.isCompleted) completer.complete(null);
      });
    } catch (e) {
      debugPrint('[MapsWebService] Directions error: $e');
      return null;
    }

    return completer.future;
  }

  /// Reverse geocode lat/lng to address
  static Future<Map<String, String>?> reverseGeocode(LatLng location) async {
    if (!isSupported) return null;

    final completer = Completer<Map<String, String>?>();

    try {
      final service = js.context['MapsWebService'];

      if (service == null) return null;

      final callback = js.allowInterop((dynamic result) {
        if (result != null) {
          final jsResult = js.JsObject.fromBrowserObject(result as js.JsObject);
          final address = jsResult['address'] as String?;
          final city = jsResult['city'] as String?;
          final fullAddress = jsResult['fullAddress'] as String?;

          if (address != null && city != null) {
            completer.complete({
              'address': address,
              'city': city,
              'fullAddress': fullAddress ?? address,
            });
            return;
          }
        }
        completer.complete(null);
      });

      service.callMethod('reverseGeocode', [
        location.latitude,
        location.longitude,
        callback,
      ]);

      Future.delayed(const Duration(seconds: 2), () {
        if (!completer.isCompleted) completer.complete(null);
      });
    } catch (e) {
      debugPrint('[MapsWebService] Reverse geocode error: $e');
      return null;
    }

    return completer.future;
  }
}
