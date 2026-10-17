import '../services/admin_service.dart';

import 'package:flutter/widgets.dart';

import 'localization_context.dart';

/// Presentation labels only; catalogue IDs, status enums and authored text stay intact.
extension AdminCatalogueLabels on BuildContext {
  String adminText(String label) => switch (label) {
    'Admin console' => l10n.adminConsole,
    'Overview' => l10n.adminOverview,
    'Buses' => l10n.adminBuses,
    'Routes' => l10n.adminRoutes,
    'Bus stops' => l10n.adminStops,
    'Users' => l10n.adminUsers,
    'Drivers' => l10n.adminDrivers,
    'Activity' => l10n.adminActivity,
    'Refresh server data' => l10n.adminRefresh,
    'Sign out' => l10n.adminSignOut,
    'Sample/Test catalogue administration' => l10n.adminSampleCatalogue,
    'Server data unavailable.' => l10n.adminUnavailable,
    'Loading verified server records...' => l10n.adminLoading,
    'No matching records.' => l10n.adminNoMatches,
    'Review access' => l10n.adminReviewAccess,
    'Assign route' => l10n.adminAssignRoute,
    'Edit profile' => l10n.adminEditProfile,
    'Review driver' => l10n.adminReviewDriver,
    'Dated departures' => l10n.adminDatedDepartures,
    'Restore' => l10n.adminRestore,
    'Edit' => l10n.adminEdit,
    'Delete' => l10n.adminDelete,
    'Finish deletion' => l10n.adminFinishDeletion,
    'Cancel' => l10n.adminCancel,
    'Delete record' => l10n.adminDeleteRecord,
    'Edit user profile' => l10n.adminEditUser,
    'Name' => l10n.adminName,
    'Phone' => l10n.adminPhone,
    'Save profile' => l10n.adminSaveProfile,
    'Assigned route' => l10n.adminAssignedRoute,
    'No route / remove assignment' => l10n.adminNoRoute,
    'Assignment reason (at least 10 characters)' => l10n.adminAssignmentReason,
    'Save assignment' => l10n.adminSaveAssignment,
    'Decision' => l10n.adminDecision,
    'Approve' => l10n.adminApprove,
    'Reject' => l10n.adminReject,
    'Revoke access' => l10n.adminRevoke,
    'Review evidence / reason' => l10n.adminReviewReason,
    'Confirm decision' => l10n.adminConfirmDecision,
    'Approved' => l10n.adminApproved,
    'Rejected' => l10n.adminRejected,
    'Revoked' => l10n.adminRevoked,
    'Pending review' => l10n.adminPending,
    'Unassigned' => l10n.adminUnassigned,
    'Add' => l10n.adminAdd,
    'bus stop' => l10n.adminBusStop,
    'bus / timetable' => l10n.adminBusTimetable,
    'route' => l10n.adminRoute,
    'Record ID' => l10n.adminRecordId,
    'Stop name' => l10n.adminStopName,
    'Source URL' => l10n.adminSourceUrl,
    'Unknown / not assessed' => l10n.adminUnknown,
    'Equipped' => l10n.adminEquipped,
    'Not equipped' => l10n.adminNotEquipped,
    'Yes - assessed' => l10n.adminYesAssessed,
    'No - assessed' => l10n.adminNoAssessed,
    'Catalogue record type' => l10n.adminCatalogueType,
    'Physical vehicle' => l10n.adminPhysicalVehicle,
    'Published timetable' => l10n.adminPublishedTimetable,
    'Route' => l10n.adminRouteField,
    'Assigned driver' => l10n.adminDriverField,
    'Scheduled time (HH:mm)' => l10n.adminScheduledTime,
    'Add a stop' => l10n.adminAddStop,
    'Saving...' => l10n.adminSaving,
    'Save catalogue record' => l10n.adminSaveCatalogue,
    'Reload reference data' => l10n.adminReloadReferences,
    'Open passenger app' => l10n.adminOpenPassenger,
    'Transit administration' => l10n.adminTransit,
    'Change confirmed by the server.' => l10n.adminChangeConfirmed,
    'I reviewed the source and the entered catalogue details.' =>
      l10n.adminSourceChecked,
    'This removes the catalogue record. Referenced records and active buses cannot be deleted. This action cannot be undone.' =>
      l10n.adminDeleteHelp,
    'I checked this driver\'s identity and operating authority.' =>
      l10n.adminDriverChecked,
    'Could not load server records. Check your connection/access and retry.' =>
      l10n.adminSourceLoadError,
    'Latitude' => l10n.adminLatitude,
    'Longitude' => l10n.adminLongitude,
    'Ramp capability' => l10n.adminRamp,
    'Elevator capability' => l10n.adminElevator,
    'Assessed step-free path' => l10n.adminStepFree,
    'Route number' => l10n.adminRouteNumber,
    'Route name' => l10n.adminRouteName,
    'Description' => l10n.adminDescription,
    'Vehicle registration number' => l10n.adminVehicleRegistration,
    'Low-floor capability' => l10n.adminLowFloor,
    'Stable identifier. Cannot be changed after creation.' =>
      l10n.adminStableId,
    'Authoritative timetable, stop or operator source. This is not a live-service verification.' =>
      l10n.adminSourceHelp,
    'Maintain sourced catalogue records and review operator access. All changes require server acknowledgement.' =>
      l10n.adminOverviewHelp,
    'Driver registration is an application for access. Review identity and operating authority before approval. Approval does not verify equipment or guarantee a service.' =>
      l10n.adminRegistrationHelp,
    'Buses & timetables (loaded)' => l10n.adminBusCountLabel,
    'Routes (loaded)' => l10n.adminRouteCountLabel,
    'Bus stops (loaded)' => l10n.adminStopCountLabel,
    'Users (loaded)' => l10n.adminUserCountLabel,
    'Drivers awaiting review (loaded)' => l10n.adminDriverCountLabel,
    'Reference records could not be loaded completely. Reload before saving.' =>
      l10n.adminReferencesError,
    'No active route assignment' => l10n.adminNoActiveRoute,
    'Required' => l10n.adminRequired,
    'Review the source before saving.' => l10n.adminReviewSource,
    'Assign an approved driver to this route first, or release the previous assignment.' =>
      l10n.adminRouteFirst,
    'Login email, passwords and Auth account deletion are managed in Firebase Authentication.' =>
      l10n.adminAuthProfileHelp,
    'Access will be withdrawn and bus assignments released. Active trip/telemetry records remain for reconciliation; they are not marked completed.' =>
      l10n.adminReferenceWithdrawHelp,
    'Capability is separate from a working-equipment observation. Operational checks are recorded by the assigned driver.' =>
      l10n.adminCapabilityHelp,
    'A published timetable has no verified physical vehicle, driver or equipment status.' =>
      l10n.adminTimetableHelp,
    'Stops in travel order' => l10n.adminOrderedStops,
    'Move stop up' => l10n.adminMoveUp,
    'Move stop down' => l10n.adminMoveDown,
    'Remove stop' => l10n.adminRemoveStop,
    'Choose a route' => l10n.adminChooseRoute,
    'Use 24-hour HH:mm' => l10n.adminTimeFormat,
    'Approval is separate from route assignment. End any active trip before changing or removing a route.' =>
      l10n.adminAssignmentHelp,
    'Record the identity and operating-authority checks or decision reason.' =>
      l10n.adminReviewChecksHelp,
    'Change was not confirmed. Check access/connection and reload before retrying.' =>
      l10n.adminChangeUnconfirmed,
    'Save was not confirmed. Check connection/access and reload before retrying.' =>
      l10n.adminSaveUnconfirmed,
    'Page cursor changed. Reload.' => l10n.adminCursorChanged,
    'Account changed. Reload references.' => l10n.adminAccountReferenceChanged,
    'Administrator access is required.' => l10n.adminAccessRequired,
    'Account changed. Sign in again.' => l10n.adminAccountSignInChanged,
    'A server connection is required. Retry when online.' =>
      l10n.adminConnectionRequired,
    'This record changed. Reload it before saving.' => l10n.adminRecordChanged,
    'Select at least two distinct stops in travel order.' => l10n.adminTwoStops,
    'Every stop occurrence requires an unambiguous physical station.' =>
      l10n.adminOccurrenceStation,
    'Enter the catalogue source URL.' => l10n.adminSourceInvalid,
    'Choose vehicle or published timetable.' => l10n.adminVehicleTypeInvalid,
    'A timetable cannot have a driver assignment.' =>
      l10n.adminNoTimetableDriver,
    'Enter one HH:mm (24-hour) time per stop. Overnight times may roll over.' =>
      l10n.adminTimePerStop,
    'Use letters, numbers, underscores or hyphens for the record ID.' =>
      l10n.adminRecordIdInvalid,
    'Restore this record before editing it.' => l10n.adminRestoreFirst,
    'A referenced record is pending deletion. Restore it or choose another record.' =>
      l10n.adminReferenceDeleting,
    'A selected stop no longer exists. Reload the form.' =>
      l10n.adminStopMissing,
    'Update dependent buses before changing the route number or removing/reordering their stops.' =>
      l10n.adminDependentBuses,
    'Existing stop occurrences cannot be rebound to another station. Use new occurrence IDs.' =>
      l10n.adminOccurrenceRebind,
    'Choose an existing route with the same route number.' =>
      l10n.adminRouteMismatch,
    'Vehicle stops must follow the selected route order.' =>
      l10n.adminStopOrderInvalid,
    'Only an approved operator may be assigned.' => l10n.adminApprovedOnly,
    'Assign the approved driver to this route first.' => l10n.adminGrantFirst,
    'This bus has an active trip or broadcast. End it before changing assignment, route or stops.' =>
      l10n.adminBusActive,
    'This record is not pending deletion.' => l10n.adminNotDeleting,
    'Select an operator and enter a review/reason of 10-2000 characters.' =>
      l10n.adminReviewInputInvalid,
    'Select a driver and enter a reason of 10-2000 characters.' =>
      l10n.adminGrantInputInvalid,
    'Approve the driver before assigning a route.' => l10n.adminApproveFirst,
    'Choose an available reviewed route.' => l10n.adminReviewedRoute,
    'Enter a name (up to 100 characters) and phone (up to 40).' =>
      l10n.adminProfileInputInvalid,
    'Publish this bus timetable for a specific Colombo service date. Starting the run opens boarding; departure is recorded separately.' =>
      l10n.adminRunHelp,
    'To reschedule, cancel the previous scheduled run and publish its replacement. Stop intervals are retained; the bus timetable stays unchanged.' =>
      l10n.adminRunRescheduleHelp,
    'Start window: 5 minutes before to 30 minutes after departure. Late starts require a reason.' =>
      l10n.adminRunWindowHelp,
    'Publish dated departure' => l10n.adminRunPublish,
    'Reload departures' => l10n.adminRunReload,
    'Cancel scheduled run' => l10n.adminRunCancel,
    'Dated departure change confirmed.' => l10n.adminRunConfirmed,
    'Could not load dated departures. Retry when online.' =>
      l10n.adminRunLoadFailed,
    'Change was not confirmed. Reload and retry.' => l10n.adminRunChangeFailed,
    'Stored timetable needs administrator review.' =>
      l10n.adminRunReviewTimetable,
    'No dated departures for this bus.' => l10n.adminRunEmpty,
    'Scheduled' => l10n.adminRunScheduled,
    'Boarding' => l10n.adminRunBoarding,
    'In progress' => l10n.adminRunInProgress,
    'Completed' => l10n.adminRunCompleted,
    'Cancelled' => l10n.adminRunCancelled,
    'Status unavailable' => l10n.adminRunUnknown,
    'Choose weekdays and a date range of at most 31 days.' =>
      l10n.adminCalendarDatesInvalid,
    'Reload the published calendar.' => l10n.adminCalendarReload,
    'Only a published calendar can generate departures.' =>
      l10n.adminCalendarPublishedOnly,
    'Invalid calendar. Publish a reviewed replacement.' =>
      l10n.adminCalendarInvalid,
    'The bus timetable changed. Publish a reviewed replacement calendar.' =>
      l10n.adminCalendarBusChanged,
    'Choose a valid Colombo departure time.' => l10n.adminColomboTimeInvalid,
    'Choose an available physical bus.' => l10n.adminPhysicalBusRequired,
    'A complete reviewed timetable is required for a dated run.' =>
      l10n.adminCompleteTimetableRequired,
    'Route unavailable.' => l10n.adminRouteUnavailable,
    'Choose an unreplaced, not-started run and a public reason (5–300 characters).' =>
      l10n.adminRescheduleInputInvalid,
    'Review the current physical bus timetable first.' =>
      l10n.adminReviewBusTimetable,
    'Choose a different departure time.' => l10n.adminDifferentDeparture,
    'Review the original schedule version.' => l10n.adminReviewScheduleVersion,
    'Reconcile the active operation first.' => l10n.adminReconcileFirst,
    'Only a not-started run can be cancelled here.' =>
      l10n.adminCancelNotStartedOnly,
    'Route ID' => l10n.adminGeometryRouteId,
    'Reviewed road geometry JSON' => l10n.adminGeometryImportJson,
    'Geometry change was not confirmed. Check access, review reason and current route/stop data before retrying.' =>
      l10n.adminGeometryActionFailed,
    'Fare publications could not be loaded. Reload when connected; no empty catalogue has been confirmed.' =>
      l10n.adminFareLoadFailed,
    'Published' => l10n.adminFarePublished,
    'Archived' => l10n.adminFareArchived,
    'Invalid fare publication' => l10n.adminFarePublicationInvalid,
    'Select reviewed buses' => l10n.adminFareBusesRequired,
    'Split this publication into smaller reviewed records' =>
      l10n.adminFareSplitRequired,
    'Tariff/mapping applicability mismatch' =>
      l10n.adminFareApplicabilityMismatch,
    'Review source, stages, class and effective dates; enter a review reason.' =>
      l10n.adminFareReviewRequired,
    'Route is unavailable' => l10n.adminFareRouteUnavailable,
    'A bus itinerary or route does not match the reviewed mapping' =>
      l10n.adminFareItineraryMismatch,
    'Enter an archive reason' => l10n.adminFareArchiveReasonRequired,
    'Invalid fare catalogue text' => l10n.adminFareTextInvalid,
    'Invalid fare effective date' => l10n.adminFareDateInvalid,
    'Invalid tariff source' => l10n.adminFareSourceInvalid,
    'Unreviewed or unsupported fare table' => l10n.adminFareUnreviewed,
    'Invalid fare table' => l10n.adminFareTableInvalid,
    'Invalid fare matrix' => l10n.adminFareMatrixInvalid,
    'Invalid minor-unit fare' => l10n.adminFareMinorInvalid,
    'Unreviewed or invalid fare mapping' => l10n.adminFareMappingInvalid,
    'Invalid fare occurrences' => l10n.adminFareOccurrencesInvalid,
    'Review the geometry and enter a reason' =>
      l10n.adminGeometryReviewRequired,
    'Review the current directed route itinerary' =>
      l10n.adminGeometryRouteChanged,
    'Geometry belongs to another data mode' => l10n.adminGeometryModeMismatch,
    'Use a new reviewed version' => l10n.adminGeometryVersionRequired,
    'Review each stop coordinate and its road vertex' =>
      l10n.adminGeometryStopMismatch,
    'Enter a review reason' => l10n.adminGeometryReasonRequired,
    'No geometry to withdraw' => l10n.adminGeometryMissing,
    'Invalid reviewed route geometry' => l10n.adminGeometryDataInvalid,
    'Invalid ordered geometry stops' => l10n.adminGeometryStopsInvalid,
    'Invalid coordinates' => l10n.adminGeometryCoordinatesInvalid,
    'Stop vertices must increase' => l10n.adminGeometryVerticesInvalid,
    'Review road path resolution' => l10n.adminGeometryResolutionInvalid,
    'Route too long' => l10n.adminGeometryTooLong,
    _ => label,
  };

  String adminField(String field) => switch (field) {
    'name' => l10n.adminName,
    'phone' => l10n.adminPhone,
    'sourceUrl' => l10n.adminSourceUrl,
    'lat' => l10n.adminLatitude,
    'lng' => l10n.adminLongitude,
    'routeNo' => l10n.adminRouteNumber,
    'routeName' => l10n.adminRouteName,
    'routeId' => l10n.adminRouteField,
    'busNo' => l10n.adminVehicleRegistration,
    _ => field,
  };
  String adminKind(String kind) => switch (kind) {
    'buses' => l10n.adminBuses,
    'routes' => l10n.adminRoutes,
    'stations' => l10n.adminStops,
    'users' => l10n.adminUsers,
    _ => kind,
  };
  String adminFailure(Object error) {
    if (error is AdminValidationException) {
      if (error.code == 'required-field') {
        return l10n.adminFieldRequired(
          adminField(error.field!),
          error.maximum!,
        );
      }
      if (error.code == 'coordinate-invalid') {
        return l10n.adminCoordinateInvalid(adminField(error.field!));
      }
    }
    if (error is AdminDependencyException) {
      return l10n.adminDependencyDelete(adminKind(error.kind));
    }
    if (error is FormatException) return adminText(error.message);
    if (error is StateError) return adminText(error.message);
    return l10n.adminChangeUnconfirmed;
  }

  String adminRunStatus(String status) => switch (status) {
    'scheduled' => l10n.adminRunScheduled,
    'boarding' => l10n.adminRunBoarding,
    'in_progress' => l10n.adminRunInProgress,
    'completed' => l10n.adminRunCompleted,
    'cancelled' => l10n.adminRunCancelled,
    _ => l10n.adminRunUnknown,
  };

  String? adminImportFailure(Object? error) {
    final message = error is FormatException
        ? error.message
        : error is StateError
        ? error.message
        : null;
    return switch (message) {
      'Route ID' => l10n.adminGeometryRouteId,
      'Reviewed road geometry JSON' => l10n.adminGeometryImportJson,
      'Geometry change was not confirmed. Check access, review reason and current route/stop data before retrying.' =>
        l10n.adminGeometryActionFailed,
      'Fare publications could not be loaded. Reload when connected; no empty catalogue has been confirmed.' =>
        l10n.adminFareLoadFailed,
      'Published' => l10n.adminFarePublished,
      'Archived' => l10n.adminFareArchived,
      'Invalid fare publication' => l10n.adminFarePublicationInvalid,
      'Select reviewed buses' => l10n.adminFareBusesRequired,
      'Split this publication into smaller reviewed records' =>
        l10n.adminFareSplitRequired,
      'Tariff/mapping applicability mismatch' =>
        l10n.adminFareApplicabilityMismatch,
      'Review source, stages, class and effective dates; enter a review reason.' =>
        l10n.adminFareReviewRequired,
      'Route is unavailable' => l10n.adminFareRouteUnavailable,
      'A bus itinerary or route does not match the reviewed mapping' =>
        l10n.adminFareItineraryMismatch,
      'Enter an archive reason' => l10n.adminFareArchiveReasonRequired,
      'Invalid fare catalogue text' => l10n.adminFareTextInvalid,
      'Invalid fare effective date' => l10n.adminFareDateInvalid,
      'Invalid tariff source' => l10n.adminFareSourceInvalid,
      'Unreviewed or unsupported fare table' => l10n.adminFareUnreviewed,
      'Invalid fare table' => l10n.adminFareTableInvalid,
      'Invalid fare matrix' => l10n.adminFareMatrixInvalid,
      'Invalid minor-unit fare' => l10n.adminFareMinorInvalid,
      'Unreviewed or invalid fare mapping' => l10n.adminFareMappingInvalid,
      'Invalid fare occurrences' => l10n.adminFareOccurrencesInvalid,
      'Review the geometry and enter a reason' =>
        l10n.adminGeometryReviewRequired,
      'Review the current directed route itinerary' =>
        l10n.adminGeometryRouteChanged,
      'Geometry belongs to another data mode' => l10n.adminGeometryModeMismatch,
      'Use a new reviewed version' => l10n.adminGeometryVersionRequired,
      'Review each stop coordinate and its road vertex' =>
        l10n.adminGeometryStopMismatch,
      'Enter a review reason' => l10n.adminGeometryReasonRequired,
      'No geometry to withdraw' => l10n.adminGeometryMissing,
      'Invalid reviewed route geometry' => l10n.adminGeometryDataInvalid,
      'Invalid ordered geometry stops' => l10n.adminGeometryStopsInvalid,
      'Invalid coordinates' => l10n.adminGeometryCoordinatesInvalid,
      'Stop vertices must increase' => l10n.adminGeometryVerticesInvalid,
      'Review road path resolution' => l10n.adminGeometryResolutionInvalid,
      'Route too long' => l10n.adminGeometryTooLong,
      'This record changed. Reload it before saving.' =>
        l10n.adminRecordChanged,
      'Administrator access is required.' => l10n.adminAccessRequired,
      'Account changed. Sign in again.' => l10n.adminAccountSignInChanged,
      'A server connection is required. Retry when online.' =>
        l10n.adminConnectionRequired,
      _ => null,
    };
  }

  String adminFareState(String state) => switch (state) {
    'published' => l10n.adminFarePublished,
    'archived' => l10n.adminFareArchived,
    _ => l10n.adminRunUnknown,
  };
}
