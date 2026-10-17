import 'package:flutter/widgets.dart';

import 'localization_context.dart';

/// Fixed form options only; stored issue/category strings are unchanged.
extension ReportFormPresentation on BuildContext {
  String reportFormText(String value) => switch (value) {
    "Low Crowd" => l10n.formLowCrowd,
    "Plenty of room & wheelchair bay free" =>
      l10n.formPlentyOfRoomWheelchairBay,
    "Moderate" => l10n.formModerate,
    "Seats full, standing room available" =>
      l10n.formSeatsFullStandingRoomAvailable,
    "Crowded / Packed" => l10n.formCrowdedPacked,
    "Wheelchair space or aisle blocked" =>
      l10n.formWheelchairSpaceOrAisleBlocked,
    "Ramp & Bay" => l10n.formRampBay,
    "Ramp Working" => l10n.formRampWorking,
    "Driver assisted & deployed ramp" => l10n.formDriverAssistedDeployedRamp,
    "Ramp Broken" => l10n.formRampBroken,
    "Motor jammed or ramp broken" => l10n.formMotorJammedOrRampBroken,
    "Ramp Denied" => l10n.formRampDenied,
    "Driver did not lower or deploy" => l10n.formDriverDidNotLowerOr,
    "Bay Blocked" => l10n.formBayBlocked,
    "Blocked by bags or standing crowd" => l10n.formBlockedByBagsOrStanding,
    "Seats" => l10n.formSeats,
    "Seats Free" => l10n.formSeatsFree,
    "Elderly / disabled seats free" => l10n.formElderlyDisabledSeatsFree,
    "Seats Occupied" => l10n.formSeatsOccupied,
    "Others not giving up seats" => l10n.formOthersNotGivingUpSeats,
    "Seat Broken" => l10n.formSeatBroken,
    "Damaged or loose seating" => l10n.formDamagedOrLooseSeating,
    "Safety & Clean" => l10n.formSafetyClean,
    "Clean & Safe" => l10n.formCleanSafe,
    "Vehicle well-maintained" => l10n.formVehicleWellMaintained,
    "Dirty / Odor" => l10n.formDirtyOdor,
    "Spill or unpleasant smell" => l10n.formSpillOrUnpleasantSmell,
    "Rail Broken" => l10n.formRailBroken,
    "Grab rails or straps loose" => l10n.formGrabRailsOrStrapsLoose,
    "Reckless Driving" => l10n.formRecklessDriving,
    "Sudden jerks, unsafe ride" => l10n.formSuddenJerksUnsafeRide,
    "Elevator" => l10n.formElevator,
    "Elevator Working" => l10n.formElevatorWorking,
    "Operating smoothly & accessible" => l10n.formOperatingSmoothlyAccessible,
    "Out of Service" => l10n.formOutOfService,
    "Elevator shut down or repair" => l10n.formElevatorShutDownOrRepair,
    "Door / Button Fault" => l10n.formDoorButtonFault,
    "Doors stuck or buttons broken" => l10n.formDoorsStuckOrButtonsBroken,
    "Ramp & Path" => l10n.formRampPath,
    "Ramp Clear" => l10n.formRampClear,
    "Smooth wheelchair slope" => l10n.formSmoothWheelchairSlope,
    "Path Blocked" => l10n.formPathBlocked,
    "Vendors or parked vehicles" => l10n.formVendorsOrParkedVehicles,
    "Damaged / Steep" => l10n.formDamagedSteep,
    "Pavement cracked or steep slope" => l10n.formPavementCrackedOrSteepSlope,
    "Tactile Tiles" => l10n.formTactileTiles,
    "Tiles Intact" => l10n.formTilesIntact,
    "Guided tactile tiles clear" => l10n.formGuidedTactileTilesClear,
    "Tiles Broken" => l10n.formTilesBroken,
    "Loose tiles causing trip hazard" => l10n.formLooseTilesCausingTripHazard,
    "Unsafe Edge Gap" => l10n.formUnsafeEdgeGap,
    "Excessive gap between curb & bus" => l10n.formExcessiveGapBetweenCurbBus,
    "Shelter & Light" => l10n.formShelterLight,
    "Shelter Good" => l10n.formShelterGood,
    "Rain protection & seating intact" => l10n.formRainProtectionSeatingIntact,
    "Roof Damaged" => l10n.formRoofDamaged,
    "Damaged roof or broken benches" => l10n.formDamagedRoofOrBrokenBenches,
    "Dark / Unsafe" => l10n.formDarkUnsafe,
    "Poor night lighting in walkway" => l10n.formPoorNightLightingInWalkway,
    "Photo attached successfully!" => l10n.formPhotoAttachedSuccessfully,
    "Attach Evidence Photo" => l10n.formAttachEvidencePhoto,
    "Help verify condition for commuters with disabilities" =>
      l10n.formHelpVerifyConditionForCommuters,
    "Take Photo" => l10n.formTakePhoto,
    "From Gallery" => l10n.formFromGallery,
    "Select the exact bus or stop you observed." =>
      l10n.formSelectTheExactBusOr,
    "Choose the condition and crowding level you observed." =>
      l10n.formChooseTheConditionAndCrowding,
    "Choose the condition you observed." =>
      l10n.formChooseTheConditionYouObserved,
    "Confirm your observation" => l10n.formConfirmYourObservation,
    "Evidence: 1 photo attached" => l10n.formEvidence1PhotoAttached,
    "Your observation, note and attached photo will be public after publication. Avoid faces, identifying details and sensitive personal information. Submit only photos you have permission to share." =>
      l10n.formYourObservationNoteAndAttached,
    "Pending drafts stay on this device for up to 7 days and are removed on sign-out/account change. You can remove them from Your uploads. Removing a draft cannot recall a request already sent or delete a public report/photo." =>
      l10n.formPendingDraftsStayOnThis,
    "Android drafts use encrypted private storage. On other platforms drafts last only for this app session." =>
      l10n.formAndroidDraftsUseEncryptedPrivate,
    "Edit report" => l10n.formEditReport,
    "Confirm and submit" => l10n.formConfirmAndSubmit,
    "Community Report" => l10n.formCommunityReport,
    "Help accessible transit commuters in real-time" =>
      l10n.formHelpAccessibleTransitCommutersIn,
    "Select Bus Route" => l10n.formSelectBusRoute,
    "Which route are you traveling on or waiting for?" =>
      l10n.formWhichRouteAreYouTraveling,
    "Where is the Issue?" => l10n.formWhereIsTheIssue,
    "Choose whether you are inside a vehicle or at a station" =>
      l10n.formChooseWhetherYouAreInside,
    "Vehicle Accessibility Condition" => l10n.formVehicleAccessibilityCondition,
    "Station Accessibility Condition" => l10n.formStationAccessibilityCondition,
    "Report crowding level and wheelchair access inside the bus" =>
      l10n.formReportCrowdingLevelAndWheelchair,
    "Report elevator, ramp, and platform conditions at the stop" =>
      l10n.formReportElevatorRampAndPlatform,
    "Evidence Photo (Optional)" => l10n.formEvidencePhotoOptional,
    "Take a photo or upload from gallery to verify status" =>
      l10n.formTakeAPhotoOrUpload,
    "Additional Note (Optional)" => l10n.formAdditionalNoteOptional,
    "Add helpful details for fellow wheelchair or elderly riders" =>
      l10n.formAddHelpfulDetailsForFellow,
    "e.g. Ramp was lowered but driver needed bystander help" =>
      l10n.formEGRampWasLowered,
    "Submitting Report…" => l10n.formSubmittingReport,
    "Review and submit report" => l10n.formReviewAndSubmitReport,
    "Select a route (optional)" => l10n.formSelectARouteOptional,
    "On a Bus" => l10n.formOnABus,
    "Inside the vehicle" => l10n.formInsideTheVehicle,
    "At a Bus Stop" => l10n.formAtABusStop,
    "Station & platform" => l10n.formStationPlatform,
    "Select Specific Bus / License Plate" =>
      l10n.formSelectSpecificBusLicensePlate,
    "Select Stop along this route" => l10n.formSelectStopAlongThisRoute,
    "Crowding Level" => l10n.formCrowdingLevel,
    "Choose the crowding level you observed." =>
      l10n.formChooseTheCrowdingLevelYou,
    "Accessibility Issue Category" => l10n.formAccessibilityIssueCategory,
    "Station Facility Category" => l10n.formStationFacilityCategory,
    "Photo uploads are currently unavailable. You can submit your report without a photo." =>
      l10n.formPhotoUploadsAreCurrentlyUnavailable,
    "Photo Attached" => l10n.formPhotoAttached,
    "Will be uploaded with report" => l10n.formWillBeUploadedWithReport,
    "Remove photo" => l10n.formRemovePhoto,
    "Add Photo" => l10n.formAddPhoto,
    "Tap to take photo or choose from device" => l10n.formTapToTakePhotoOr,
    "Not selected" => l10n.formNotSelected,
    "Report Summary" => l10n.formReportSummary,
    "Location / Vehicle" => l10n.formLocationVehicle,
    "Accessibility Status" => l10n.formAccessibilityStatus,
    "Photo Evidence" => l10n.formPhotoEvidence,
    "1 photo attached" => l10n.form1PhotoAttached,
    _ => value,
  };
}
