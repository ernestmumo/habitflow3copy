import 'package:get/get.dart';

// Event types
enum EventType {
  habitAdded,
  habitUpdated,
  habitDeleted,
  habitCompleted,
  habitUncompleted,
  dataRefreshed,
}

// Event class to carry information
class AppEvent {
  final EventType type;
  final Map<String, dynamic> data;

  AppEvent(this.type, {this.data = const {}});
}

// EventBus service for app-wide communication
class EventBus extends GetxService {
  // Stream controller for events
  final _events = RxList<AppEvent>([]);

  // Method to publish an event
  void fire(EventType type, {Map<String, dynamic> data = const {}}) {
    final event = AppEvent(type, data: data);
    _events.add(event);
    print('EVENT: $type fired with data: $data');
  }

  // Method to listen for specific event types
  void listen(EventType type, Function(Map<String, dynamic>) callback) {
    ever(_events, (events) {
      // Check if the last event matches the requested type
      if (events.isNotEmpty && events.last.type == type) {
        callback(events.last.data);
      }
    });
  }

  // Method to listen for multiple event types
  void listenToMultiple(List<EventType> types, Function(EventType, Map<String, dynamic>) callback) {
    ever(_events, (events) {
      // Check if the last event matches any of the requested types
      if (events.isNotEmpty && types.contains(events.last.type)) {
        callback(events.last.type, events.last.data);
      }
    });
  }

  // Clear events (for testing or resetting)
  void clear() {
    _events.clear();
  }
}
