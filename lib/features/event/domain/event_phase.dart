import 'package:scanpdf/core/constants/app_constants.dart';

/// Receipt Rescue Challenge phases. Pure and clock-injectable so the
/// resolver and screens are unit-testable.
enum EventPhase { upcoming, live, ended }

EventPhase eventPhaseAt(DateTime now) {
  if (now.isBefore(AppConstants.eventStart)) return EventPhase.upcoming;
  if (now.isAfter(AppConstants.eventEnd)) return EventPhase.ended;
  return EventPhase.live;
}

EventPhase currentEventPhase() => eventPhaseAt(DateTime.now());
