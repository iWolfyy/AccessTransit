# Report publication

Reports have three delivery states: Published, Pending upload, and Failed. Published means Firestore acknowledged the write; it does not mean another commuter has read it.

The sender's durable outbox stores metadata and photo bytes on the device. Photos upload before publishing; Firestore receives a shared HTTPS URL. Retry retains the report ID and reuses an already saved photo URL. Pending and failed entries appear in My Reports. Pending entries retry for their original signed-in account every minute while the app is running. Public feeds and accessibility calculations exclude unpublished and demo reports.

## Free photo storage setup

Firebase Auth and Firestore remain in use. Firebase Storage has been removed; there is no Blaze requirement for this photo implementation. Photos use [Cloudinary Free](https://cloudinary.com/pricing), which requires no credit card and currently includes 25 monthly credits. Stay within the free plan's usage allowance; it is not unlimited storage or bandwidth.

1. Create an Image and Video APIs **Free** account at https://cloudinary.com/users/register/free. Do not select a paid plan.
2. The app's default **Cloud name** is `dyrynkuh3`. Override it with `CLOUDINARY_CLOUD_NAME` for another product environment.
3. In Settings > Upload > Upload presets, create `access_transit_reports` with **Unsigned** signing mode. This is the app's default preset.
4. Restrict the preset to `jpg,jpeg,png,webp` and maximum file size `2097152` bytes (2 MiB). Use an asset folder such as `report_photos`. Do not enable paid add-ons.
5. The supplied cloud name and preset are configured by default. Run the app:

```powershell
flutter run
```

To use another environment, override `CLOUDINARY_CLOUD_NAME` and `CLOUDINARY_UPLOAD_PRESET` with `--dart-define` on run/build commands. Configuration changes require a full restart/build. The app does not need an API key or API secret; never put your API secret in client code. With empty configuration, photo attachment is unavailable and text-only reports still submit. Existing queued photo reports retain their bytes for retry after setup.

Uploads follow the [official unsigned upload API](https://cloudinary.com/documentation/upload_images). Only signed-in report authors can initiate uploads through the app. An unsigned preset itself does not authenticate Firebase users: anyone who obtains its name can upload directly, so enforce format/size restrictions in the preset, monitor free usage, and rotate/disable the preset if abused. Images use publicly viewable HTTPS URLs for community evidence. A timeout before the URL is saved can leave an orphan image; review unused assets in the dashboard to conserve storage.

## Validation

Automated tests use injected uploaders/writers and an HTTP mock. They cover unsigned upload requests, file limits, URL validation, service errors, durable retry, report acknowledgement, and public visibility without publishing live test records.

The user has supplied the cloud name and confirmed saving the unsigned preset. Live photo upload remains unverified. Submit a photo from account A, wait for Published, and open it from account B on another device. Test offline submission, app restart, reconnection and retry. Bad preset or file rejection must show Failed; network/server/rate-limit errors remain Pending upload. Text-only reports do not call the photo provider.
