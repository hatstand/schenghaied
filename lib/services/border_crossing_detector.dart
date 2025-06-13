import 'package:time_machine/time_machine.dart';

/// Enum to define the type of border crossing.
enum BorderCrossingEventType { entry, exit }

/// Represents a detected Schengen zone border crossing event.
class BorderCrossingEvent {
  final BorderCrossingEventType eventType;
  final Instant timestamp;
  final String source;
  final double confidence;
  final double? latitude;
  final double? longitude;

  BorderCrossingEvent({
    required this.eventType,
    required this.timestamp,
    required this.source,
    this.confidence = 1.0, // Default to 100% confidence
    this.latitude,
    this.longitude,
  });

  @override
  String toString() {
    return 'BorderCrossingEvent{eventType: $eventType, timestamp: $timestamp, source: $source, confidence: $confidence, lat: $latitude, lon: $longitude}';
  }
}

/// Interface for services that detect physical crossings of the Schengen zone border.
///
/// Implementations of this interface could use various sources such as:
/// - Geolocation APIs (e.g., geofencing).
/// - Telephony APIs (e.g., network changes indicating country change).
/// - Manual user input (though less "detected").
abstract class BorderCrossingDetector {
  /// A stream of [BorderCrossingEvent]s that are emitted when a border crossing is detected.
  Stream<BorderCrossingEvent> get borderCrossingEvents;

  /// Starts listening for border crossing events from the underlying source.
  ///
  /// This might involve setting up geofences, subscribing to telephony events, etc.
  /// Should handle any necessary permissions if not already granted.
  Future<void> startListening();

  /// Stops listening for border crossing events.
  ///
  /// Releases any resources used by the detector.
  Future<void> stopListening();

  /// Requests necessary permissions from the user (e.g., location, phone state).
  ///
  /// Returns `true` if permissions were granted, `false` otherwise.
  Future<bool> requestPermission();

  /// Checks the current status of required permissions.
  ///
  /// Returns `true` if all necessary permissions are granted, `false` otherwise.
  Future<bool> checkPermissionStatus();
}
