import 'dart:async';

import 'package:access_transit/l10n/app_localizations.dart';
import 'package:access_transit/l10n/report_form_presentation.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/models/station.dart';
import 'package:access_transit/screens/journey/report_condition_screen.dart';
import 'package:access_transit/screens/journey/report_submitted_screen.dart';
import 'package:access_transit/services/accessibility_preferences_service.dart';
import 'package:access_transit/services/report_submission_service.dart';
import 'package:access_transit/services/transit_catalogue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import 'bus_details_flow_test.dart' show vehicle;
import 'report_delivery_layout_test.dart' show MemoryStorage;
import 'registration_onboarding_localization_test.dart' show host, narrow;

class PickerFixture extends ImagePicker {
  bool reject = false;
  ImageSource? selected;
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    selected = source;
    if (reject) throw StateError('PRIVATE CAMERA ERROR');
    return null;
  }
}

Future<void> press(WidgetTester t, String value, {bool settle = true}) async {
  t.testTextInput.hide();
  await t.pumpAndSettle();
  final target = find.text(value).first;
  if (find.text(value).evaluate().isEmpty) {
    t
        .state<ScrollableState>(
          find
              .byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
              )
              .last,
        )
        .position
        .jumpTo(0);
    await t.pumpAndSettle();
    await t.scrollUntilVisible(
      find.text(value),
      250,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .last,
      maxScrolls: 40,
    );
  }
  await Scrollable.ensureVisible(t.element(target), alignment: .5);
  await t.pumpAndSettle();
  await t.tap(target);
  if (settle) {
    await t.pumpAndSettle();
  } else {
    await t.pump();
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilityPreferencesService.instance.init(userId: 'author');
    await AccessibilityPreferencesService.instance.setHighContrast(true);
    // ignore: invalid_use_of_visible_for_testing_member
    TransitCatalogue.installFixtures({
      'stations': {
        's': const Station(
          id: 's',
          name: 'Original Stop',
          hasElevator: true,
          hasRamp: true,
          lat: 6.9,
          lng: 79.8,
        ).toMap(),
      },
      'buses': {vehicle.id: vehicle.toMap()},
      'routes': {},
    });
  });
  tearDown(() {
    // ignore: invalid_use_of_visible_for_testing_member
    TransitCatalogue.resetMemoryForTesting();
  });
  for (final lang in ['en', 'si', 'ta']) {
    testWidgets(
      'station form $lang review preserves payload and waits for publication',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        final ack = Completer<void>();
        Report? payload;
        final service = ReportSubmissionService(
          storage: MemoryStorage(),
          publisher: (r) async {
            payload = r;
            await ack.future;
          },
        );
        await t.pumpWidget(
          host(
            lang,
            ReportConditionScreen(
              targetId: 's',
              currentUserId: () => 'author',
              submissionService: service,
            ),
          ),
        );
        await t.pumpAndSettle();
        await press(t, l.formElevatorWorking);
        await t.scrollUntilVisible(
          find.byType(TextField),
          250,
          scrollable: find
              .byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
              )
              .last,
        );
        await t.enterText(find.byType(TextField), 'Original rider note');
        await press(t, l.formReviewAndSubmitReport);
        expect(find.text(l.formConfirmYourObservation), findsOneWidget);
        expect(find.text(l.formReviewPublicNotice), findsOneWidget);
        await press(t, l.formReviewDetails);
        expect(find.text(l.formPendingDraftsStayOnThis), findsOneWidget);
        expect(find.text(l.formAndroidDraftsUseEncryptedPrivate), findsOneWidget);
        expect(t.takeException(), isNull);
        await press(t, l.formReviewDetails);
        expect(
          find.text(l.formReviewCondition(l.formElevatorWorking)),
          findsOneWidget,
        );
        expect(
          find.text(l.formReviewNote('Original rider note')),
          findsOneWidget,
        );
        expect(payload, isNull);
        await press(t, l.formEditReport);
        expect(find.byType(AlertDialog), findsNothing);
        await press(t, l.formReviewAndSubmitReport);
        await press(t, l.formConfirmAndSubmit, settle: false);
        expect(payload?.subCategory, 'Elevator Working');
        expect(payload?.category, 'elevatorOut');
        expect(payload?.targetId, 's');
        expect(payload?.description, 'Original rider note');
        expect(find.byType(ReportSubmittedScreen), findsNothing);
        ack.complete();
        await t.pumpAndSettle();
        expect(find.byType(ReportSubmittedScreen), findsOneWidget);
        expect(find.text(l.deliveryPublished), findsOneWidget);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        service.dispose();
      },
    );

    testWidgets(
      'bus form $lang requires observation and keeps stable crowding values',
      (t) async {
        narrow(t);
        final l = lookupAppLocalizations(Locale(lang));
        Report? payload;
        final service = ReportSubmissionService(
          storage: MemoryStorage(),
          publisher: (r) async {
            payload = r;
          },
        );
        await t.pumpWidget(
          host(
            lang,
            ReportConditionScreen(
              targetType: 'bus',
              targetId: vehicle.id,
              currentUserId: () => 'author',
              submissionService: service,
            ),
          ),
        );
        await t.pumpAndSettle();
        await press(t, l.formReviewAndSubmitReport);
        expect(find.text(l.formChooseTheConditionAndCrowding), findsOneWidget);
        await t.pump(const Duration(seconds: 5));
        await t.pumpAndSettle();
        await press(t, l.formLowCrowd);
        await press(t, l.formRampWorking);
        await press(t, l.formReviewAndSubmitReport);
        await press(t, l.formConfirmAndSubmit);
        expect(payload?.crowdingLevel, 'low');
        expect(payload?.category, 'rampAccess');
        expect(payload?.problemType, 'Crowding: Low Crowd • Ramp Working');
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        service.dispose();
      },
    );

    testWidgets('form $lang rejects account changes while reviewing', (
      t,
    ) async {
      narrow(t);
      final l = lookupAppLocalizations(Locale(lang));
      var actor = 'author', writes = 0;
      final service = ReportSubmissionService(
        storage: MemoryStorage(),
        publisher: (_) async {
          writes++;
        },
      );
      await t.pumpWidget(
        host(
          lang,
          ReportConditionScreen(
            targetId: 's',
            currentUserId: () => actor,
            submissionService: service,
          ),
        ),
      );
      await t.pumpAndSettle();
      await press(t, l.formElevatorWorking);
      await press(t, l.formReviewAndSubmitReport);
      actor = 'other';
      await press(t, l.formConfirmAndSubmit);
      expect(find.text(l.formAccountChanged), findsOneWidget);
      expect(writes, 0);
      expect(find.byType(ReportSubmittedScreen), findsNothing);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      service.dispose();
    });

    testWidgets('form $lang category changes keep full option labels usable', (
      t,
    ) async {
      narrow(t);
      final l = lookupAppLocalizations(Locale(lang));
      await t.pumpWidget(
        host(
          lang,
          ReportConditionScreen(targetId: 's', currentUserId: () => 'author'),
        ),
      );
      await t.pumpAndSettle();
      for (final pair in [
        (l.formRampPath, l.formDamagedSteep),
        (l.formTactileTiles, l.formUnsafeEdgeGap),
        (l.formShelterLight, l.formDarkUnsafe),
      ]) {
        await press(t, pair.$1);
        await press(t, pair.$2);
        expect(t.takeException(), isNull);
      }
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(
        host(
          lang,
          ReportConditionScreen(
            targetType: 'bus',
            targetId: vehicle.id,
            currentUserId: () => 'author',
          ),
        ),
      );
      await t.pumpAndSettle();
      for (final pair in [
        (l.formSeats, l.formSeatBroken),
        (l.formSafetyClean, l.formRecklessDriving),
      ]) {
        await press(t, pair.$1);
        await press(t, pair.$2);
        expect(t.takeException(), isNull);
      }
      expect(find.byType(ReportConditionScreen), findsOneWidget);
    });

    testWidgets('form $lang camera/gallery cancel and failure preserve draft', (
      t,
    ) async {
      narrow(t);
      final l = lookupAppLocalizations(Locale(lang)), picker = PickerFixture();
      await t.pumpWidget(
        host(
          lang,
          ReportConditionScreen(
            targetId: 's',
            currentUserId: () => 'author',
            imagePicker: picker,
          ),
        ),
      );
      await t.pumpAndSettle();
      await press(t, l.formAddPhoto);
      expect(find.text(l.formAttachEvidencePhoto), findsOneWidget);
      await press(t, l.formFromGallery);
      expect(picker.selected, ImageSource.gallery);
      expect(find.text(l.formPhotoAttachedSuccessfully), findsNothing);
      picker.reject = true;
      await press(t, l.formAddPhoto);
      await press(t, l.formTakePhoto);
      expect(picker.selected, ImageSource.camera);
      expect(find.text(l.formPhotoFailed), findsOneWidget);
      expect(find.textContaining('PRIVATE CAMERA ERROR'), findsNothing);
      expect(find.byType(ReportConditionScreen), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets(
      'form $lang translates photo controls and preserves unknown data',
      (t) async {
        final l = lookupAppLocalizations(Locale(lang));
        await t.pumpWidget(
          host(
            lang,
            Builder(
              builder: (c) {
                expect(c.reportFormText('Take Photo'), l.formTakePhoto);
                expect(c.reportFormText('From Gallery'), l.formFromGallery);
                expect(c.reportFormText('Remove photo'), l.formRemovePhoto);
                expect(c.reportFormText('Original note'), 'Original note');
                return const SizedBox();
              },
            ),
          ),
        );
      },
    );
  }
}
