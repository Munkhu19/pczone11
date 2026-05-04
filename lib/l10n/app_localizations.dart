import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_mn.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('mn')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'E-Sport Center'**
  String get appTitle;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get changeLanguage;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'E-SPORT CENTER'**
  String get loginTitle;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @switchToSignUp.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get switchToSignUp;

  /// No description provided for @switchToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get switchToSignIn;

  /// No description provided for @ownerSignUpOption.
  ///
  /// In en, this message translates to:
  /// **'Register with owner request'**
  String get ownerSignUpOption;

  /// No description provided for @ownerSignUpHint.
  ///
  /// In en, this message translates to:
  /// **'This does not create an owner account immediately. Your account will be created as pending until admin approval.'**
  String get ownerSignUpHint;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully.'**
  String get accountCreated;

  /// No description provided for @usernameAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This email is already in use.'**
  String get usernameAlreadyExists;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address.'**
  String get authInvalidEmail;

  /// No description provided for @authEmailPasswordNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Email/Password sign-in is disabled in Firebase.'**
  String get authEmailPasswordNotEnabled;

  /// No description provided for @authUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get authUserDisabled;

  /// No description provided for @authTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get authTooManyRequests;

  /// No description provided for @authApiKeyInvalid.
  ///
  /// In en, this message translates to:
  /// **'Firebase API key is invalid for this app.'**
  String get authApiKeyInvalid;

  /// No description provided for @authFirebaseNotInitialized.
  ///
  /// In en, this message translates to:
  /// **'Firebase is not initialized correctly.'**
  String get authFirebaseNotInitialized;

  /// No description provided for @authWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak.'**
  String get authWeakPassword;

  /// No description provided for @authNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your internet.'**
  String get authNetworkError;

  /// No description provided for @authUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please try again.'**
  String get authUnknownError;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid username or password'**
  String get invalidCredentials;

  /// No description provided for @centersTitle.
  ///
  /// In en, this message translates to:
  /// **'E-SPORT CENTERS'**
  String get centersTitle;

  /// No description provided for @homeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// No description provided for @searchCenterHint.
  ///
  /// In en, this message translates to:
  /// **'Search center...'**
  String get searchCenterHint;

  /// No description provided for @noCentersFound.
  ///
  /// In en, this message translates to:
  /// **'No centers found'**
  String get noCentersFound;

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'Center Map'**
  String get mapTitle;

  /// No description provided for @mapTab.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapTab;

  /// No description provided for @bookingHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking History'**
  String get bookingHistoryTitle;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address: {address}'**
  String addressLabel(Object address);

  /// No description provided for @pcCountLabel.
  ///
  /// In en, this message translates to:
  /// **'PC count: {count}'**
  String pcCountLabel(Object count);

  /// No description provided for @pcSpecLabel.
  ///
  /// In en, this message translates to:
  /// **'PC spec: {spec}'**
  String pcSpecLabel(Object spec);

  /// No description provided for @pricePerHourLabel.
  ///
  /// In en, this message translates to:
  /// **'Price: {price}₮ / hour'**
  String pricePerHourLabel(Object price);

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone: {phone}'**
  String phoneLabel(Object phone);

  /// No description provided for @selectPcSeats.
  ///
  /// In en, this message translates to:
  /// **'Select PC Seats'**
  String get selectPcSeats;

  /// No description provided for @makeBooking.
  ///
  /// In en, this message translates to:
  /// **'Make Booking'**
  String get makeBooking;

  /// No description provided for @selectSeatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Seats - {center}'**
  String selectSeatsTitle(Object center);

  /// No description provided for @bookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get bookingTitle;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields.'**
  String get fillAllFields;

  /// No description provided for @selectAtLeastOneSeat.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one PC seat.'**
  String get selectAtLeastOneSeat;

  /// No description provided for @invalidPlayDuration.
  ///
  /// In en, this message translates to:
  /// **'Play duration must be a positive number.'**
  String get invalidPlayDuration;

  /// No description provided for @bookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking Confirmed'**
  String get bookingConfirmed;

  /// No description provided for @bookingSummary.
  ///
  /// In en, this message translates to:
  /// **'{center}\\nSeats: {seats}\\nTime: {time}'**
  String bookingSummary(Object center, Object seats, Object time);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @noneSelected.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noneSelected;

  /// No description provided for @centerLabel.
  ///
  /// In en, this message translates to:
  /// **'Center: {center}'**
  String centerLabel(Object center);

  /// No description provided for @selectedSeatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected seats: {seats}'**
  String selectedSeatsLabel(Object seats);

  /// No description provided for @bookingStartTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get bookingStartTime;

  /// No description provided for @bookingTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time: {time}'**
  String bookingTimeLabel(Object time);

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @phoneMustBe8Digits.
  ///
  /// In en, this message translates to:
  /// **'Phone number must be exactly 8 digits.'**
  String get phoneMustBe8Digits;

  /// No description provided for @playDurationHours.
  ///
  /// In en, this message translates to:
  /// **'Play duration (hours)'**
  String get playDurationHours;

  /// No description provided for @invalidStartTime.
  ///
  /// In en, this message translates to:
  /// **'Start time must be in the future.'**
  String get invalidStartTime;

  /// No description provided for @confirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get confirmBooking;

  /// No description provided for @totalPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Total: {price}₮'**
  String totalPriceLabel(Object price);

  /// No description provided for @bookingReceipt.
  ///
  /// In en, this message translates to:
  /// **'{center}\\nSeats: {seats}\\nHours: {hours}\\nPrice/hour: {pricePerHour}₮\\nTotal: {totalPrice}₮'**
  String bookingReceipt(Object center, Object seats, Object hours, Object pricePerHour, Object totalPrice);

  /// No description provided for @cancelBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get cancelBookingTitle;

  /// No description provided for @cancelBookingQuestion.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking for {center}?'**
  String cancelBookingQuestion(Object center);

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, cancel'**
  String get yesCancel;

  /// No description provided for @bookingCanceled.
  ///
  /// In en, this message translates to:
  /// **'Booking canceled.'**
  String get bookingCanceled;

  /// No description provided for @bookingAlreadyCanceled.
  ///
  /// In en, this message translates to:
  /// **'Booking already canceled.'**
  String get bookingAlreadyCanceled;

  /// No description provided for @clearCanceledBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear canceled bookings'**
  String get clearCanceledBookingsTitle;

  /// No description provided for @clearCanceledBookingsMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove all canceled bookings from your history?'**
  String get clearCanceledBookingsMessage;

  /// No description provided for @clearCanceledBookingsAction.
  ///
  /// In en, this message translates to:
  /// **'Clear canceled'**
  String get clearCanceledBookingsAction;

  /// No description provided for @canceledBookingsCleared.
  ///
  /// In en, this message translates to:
  /// **'Canceled bookings cleared.'**
  String get canceledBookingsCleared;

  /// No description provided for @noBookingHistory.
  ///
  /// In en, this message translates to:
  /// **'No booking history yet.'**
  String get noBookingHistory;

  /// No description provided for @statusCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get statusCanceled;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @customerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer: {name}'**
  String customerLabel(Object name);

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration: {hours} hour(s)'**
  String durationLabel(Object hours);

  /// No description provided for @seatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Seats: {seats}'**
  String seatsLabel(Object seats);

  /// No description provided for @createdLabel.
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String createdLabel(Object date);

  /// No description provided for @canceledLabel.
  ///
  /// In en, this message translates to:
  /// **'Canceled: {date}'**
  String canceledLabel(Object date);

  /// No description provided for @cancelBookingAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get cancelBookingAction;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get profileNotSignedIn;

  /// No description provided for @profileNoDisplayName.
  ///
  /// In en, this message translates to:
  /// **'No display name'**
  String get profileNoDisplayName;

  /// No description provided for @profileUidLabel.
  ///
  /// In en, this message translates to:
  /// **'UID: {uid}'**
  String profileUidLabel(Object uid);

  /// No description provided for @profileDisplayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get profileDisplayNameLabel;

  /// No description provided for @profileSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get profileSaveButton;

  /// No description provided for @profileAvatarUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload avatar'**
  String get profileAvatarUpload;

  /// No description provided for @profileAvatarUpdated.
  ///
  /// In en, this message translates to:
  /// **'Avatar updated'**
  String get profileAvatarUpdated;

  /// No description provided for @profileAvatarUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload avatar'**
  String get profileAvatarUpdateFailed;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get profileUpdateFailed;

  /// No description provided for @profileAccountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileAccountSection;

  /// No description provided for @profileEditSection.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditSection;

  /// No description provided for @profileActivitySection.
  ///
  /// In en, this message translates to:
  /// **'Account activity'**
  String get profileActivitySection;

  /// No description provided for @profileSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile settings'**
  String get profileSettingsTitle;

  /// No description provided for @profileRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get profileRoleLabel;

  /// No description provided for @profileUidTitle.
  ///
  /// In en, this message translates to:
  /// **'UID'**
  String get profileUidTitle;

  /// No description provided for @profileCreatedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get profileCreatedAtLabel;

  /// No description provided for @profileLastSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Last sign-in'**
  String get profileLastSignInTitle;

  /// No description provided for @profileCopyAction.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get profileCopyAction;

  /// No description provided for @profileEmailCopied.
  ///
  /// In en, this message translates to:
  /// **'Email copied'**
  String get profileEmailCopied;

  /// No description provided for @profileUidCopied.
  ///
  /// In en, this message translates to:
  /// **'UID copied'**
  String get profileUidCopied;

  /// No description provided for @profileChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get profileChangePassword;

  /// No description provided for @profilePasswordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent to {email}'**
  String profilePasswordResetSent(Object email);

  /// No description provided for @profileEmailVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Email verification'**
  String get profileEmailVerificationTitle;

  /// No description provided for @profileEmailVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get profileEmailVerified;

  /// No description provided for @profileEmailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get profileEmailNotVerified;

  /// No description provided for @profileSendVerification.
  ///
  /// In en, this message translates to:
  /// **'Send verification'**
  String get profileSendVerification;

  /// No description provided for @profileRefreshVerification.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get profileRefreshVerification;

  /// No description provided for @profileVerificationSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent to {email}'**
  String profileVerificationSent(Object email);

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @profileLastSignInLabel.
  ///
  /// In en, this message translates to:
  /// **'Last sign-in: {date}'**
  String profileLastSignInLabel(Object date);

  /// No description provided for @ownerRoleCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get ownerRoleCustomer;

  /// No description provided for @adminRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminRoleLabel;

  /// No description provided for @ownerRolePending.
  ///
  /// In en, this message translates to:
  /// **'Owner pending'**
  String get ownerRolePending;

  /// No description provided for @ownerRoleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get ownerRoleOwner;

  /// No description provided for @ownerApplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply as owner'**
  String get ownerApplyTitle;

  /// No description provided for @ownerApplyMessage.
  ///
  /// In en, this message translates to:
  /// **'Send a request to become an owner? Until approval, you will not have owner access.'**
  String get ownerApplyMessage;

  /// No description provided for @ownerApplyAction.
  ///
  /// In en, this message translates to:
  /// **'Apply as owner'**
  String get ownerApplyAction;

  /// No description provided for @ownerApplySubmitted.
  ///
  /// In en, this message translates to:
  /// **'Owner request submitted. Please wait for approval.'**
  String get ownerApplySubmitted;

  /// No description provided for @ownerApplicationFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Owner application'**
  String get ownerApplicationFormTitle;

  /// No description provided for @ownerApplicationFormSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Submit your center details for admin review.'**
  String get ownerApplicationFormSubtitle;

  /// No description provided for @ownerApplicationCenterName.
  ///
  /// In en, this message translates to:
  /// **'Center name'**
  String get ownerApplicationCenterName;

  /// No description provided for @ownerApplicationPhone.
  ///
  /// In en, this message translates to:
  /// **'Contact phone'**
  String get ownerApplicationPhone;

  /// No description provided for @ownerApplicationAddress.
  ///
  /// In en, this message translates to:
  /// **'Center address'**
  String get ownerApplicationAddress;

  /// No description provided for @ownerApplicationLink.
  ///
  /// In en, this message translates to:
  /// **'Facebook page or Google Maps link'**
  String get ownerApplicationLink;

  /// No description provided for @ownerApplicationNote.
  ///
  /// In en, this message translates to:
  /// **'Additional note'**
  String get ownerApplicationNote;

  /// No description provided for @ownerApplicationSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit owner request'**
  String get ownerApplicationSubmit;

  /// No description provided for @ownerApplicationRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill center name, phone, and address.'**
  String get ownerApplicationRequiredFields;

  /// No description provided for @ownerPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Owner request pending'**
  String get ownerPendingTitle;

  /// No description provided for @ownerPendingHeading.
  ///
  /// In en, this message translates to:
  /// **'Your owner request is under review'**
  String get ownerPendingHeading;

  /// No description provided for @ownerPendingMessage.
  ///
  /// In en, this message translates to:
  /// **'We received your request. You will get owner access after approval.'**
  String get ownerPendingMessage;

  /// No description provided for @ownerPendingInline.
  ///
  /// In en, this message translates to:
  /// **'Your owner request has been submitted and is waiting for approval.'**
  String get ownerPendingInline;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboardTitle;

  /// No description provided for @adminCentersTitle.
  ///
  /// In en, this message translates to:
  /// **'All Centers'**
  String get adminCentersTitle;

  /// No description provided for @adminUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminUsersTitle;

  /// No description provided for @adminUsersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No users found.'**
  String get adminUsersEmpty;

  /// No description provided for @adminPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending requests'**
  String get adminPendingRequests;

  /// No description provided for @adminOwnersCount.
  ///
  /// In en, this message translates to:
  /// **'Owners'**
  String get adminOwnersCount;

  /// No description provided for @adminCustomersCount.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get adminCustomersCount;

  /// No description provided for @adminAdminsCount.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get adminAdminsCount;

  /// No description provided for @adminCentersCount.
  ///
  /// In en, this message translates to:
  /// **'Centers'**
  String get adminCentersCount;

  /// No description provided for @adminBookingsCount.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get adminBookingsCount;

  /// No description provided for @adminRevenueTotal.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get adminRevenueTotal;

  /// No description provided for @ownerRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Owner requests'**
  String get ownerRequestsTitle;

  /// No description provided for @ownerRequestsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pending owner requests.'**
  String get ownerRequestsEmpty;

  /// No description provided for @ownerApproveAction.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get ownerApproveAction;

  /// No description provided for @ownerRejectAction.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get ownerRejectAction;

  /// No description provided for @ownerRequestApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved owner request for {email}'**
  String ownerRequestApproved(Object email);

  /// No description provided for @ownerRequestRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected owner request for {email}'**
  String ownerRequestRejected(Object email);

  /// No description provided for @adminDeleteUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete user data'**
  String get adminDeleteUserTitle;

  /// No description provided for @adminDeleteUserMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete all app data for {email}? Firebase Authentication user deletion still needs to be done separately.'**
  String adminDeleteUserMessage(Object email);

  /// No description provided for @adminDeleteUserAction.
  ///
  /// In en, this message translates to:
  /// **'Delete user data'**
  String get adminDeleteUserAction;

  /// No description provided for @adminDeleteUserProtected.
  ///
  /// In en, this message translates to:
  /// **'Protected admin account'**
  String get adminDeleteUserProtected;

  /// No description provided for @adminUserDeleted.
  ///
  /// In en, this message translates to:
  /// **'App data deleted for {email}.'**
  String adminUserDeleted(Object email);

  /// No description provided for @adminSetAsOwner.
  ///
  /// In en, this message translates to:
  /// **'Set as owner'**
  String get adminSetAsOwner;

  /// No description provided for @adminSetAsCustomer.
  ///
  /// In en, this message translates to:
  /// **'Set as customer'**
  String get adminSetAsCustomer;

  /// No description provided for @adminUserPromotedOwner.
  ///
  /// In en, this message translates to:
  /// **'{email} is now an owner.'**
  String adminUserPromotedOwner(Object email);

  /// No description provided for @adminUserSetCustomer.
  ///
  /// In en, this message translates to:
  /// **'{email} is now a customer.'**
  String adminUserSetCustomer(Object email);

  /// No description provided for @ownerDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Owner Dashboard'**
  String get ownerDashboardTitle;

  /// No description provided for @ownerCentersTitle.
  ///
  /// In en, this message translates to:
  /// **'My Centers'**
  String get ownerCentersTitle;

  /// No description provided for @ownerBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Center Bookings'**
  String get ownerBookingsTitle;

  /// No description provided for @ownerCentersCount.
  ///
  /// In en, this message translates to:
  /// **'Owned centers'**
  String get ownerCentersCount;

  /// No description provided for @ownerBookingsCount.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get ownerBookingsCount;

  /// No description provided for @ownerRevenueTotal.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get ownerRevenueTotal;

  /// No description provided for @ownerOccupiedSeats.
  ///
  /// In en, this message translates to:
  /// **'Occupied seats'**
  String get ownerOccupiedSeats;

  /// No description provided for @ownerRecentBookings.
  ///
  /// In en, this message translates to:
  /// **'Recent bookings'**
  String get ownerRecentBookings;

  /// No description provided for @ownerNoBookings.
  ///
  /// In en, this message translates to:
  /// **'No bookings for your centers yet.'**
  String get ownerNoBookings;

  /// No description provided for @ownerNoBookingsForFilter.
  ///
  /// In en, this message translates to:
  /// **'No bookings match this filter.'**
  String get ownerNoBookingsForFilter;

  /// No description provided for @ownerClearBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear canceled bookings'**
  String get ownerClearBookingsTitle;

  /// No description provided for @ownerClearBookingsMessage.
  ///
  /// In en, this message translates to:
  /// **'Clear canceled bookings for your centers?'**
  String get ownerClearBookingsMessage;

  /// No description provided for @ownerClearBookingsAction.
  ///
  /// In en, this message translates to:
  /// **'Clear canceled'**
  String get ownerClearBookingsAction;

  /// No description provided for @ownerBookingsCleared.
  ///
  /// In en, this message translates to:
  /// **'Canceled bookings cleared.'**
  String get ownerBookingsCleared;

  /// No description provided for @ownerFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ownerFilterAll;

  /// No description provided for @ownerNoCenters.
  ///
  /// In en, this message translates to:
  /// **'You do not own any centers yet.'**
  String get ownerNoCenters;

  /// No description provided for @ownerAddCenter.
  ///
  /// In en, this message translates to:
  /// **'Add center'**
  String get ownerAddCenter;

  /// No description provided for @ownerEditCenter.
  ///
  /// In en, this message translates to:
  /// **'Edit center'**
  String get ownerEditCenter;

  /// No description provided for @ownerSaveCenter.
  ///
  /// In en, this message translates to:
  /// **'Save center'**
  String get ownerSaveCenter;

  /// No description provided for @ownerDeleteCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete center'**
  String get ownerDeleteCenterTitle;

  /// No description provided for @ownerDeleteCenterMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {center} completely? This will also remove its bookings and seat states.'**
  String ownerDeleteCenterMessage(Object center);

  /// No description provided for @ownerDeleteCenterAction.
  ///
  /// In en, this message translates to:
  /// **'Delete center'**
  String get ownerDeleteCenterAction;

  /// No description provided for @ownerCenterDeleted.
  ///
  /// In en, this message translates to:
  /// **'{center} deleted.'**
  String ownerCenterDeleted(Object center);

  /// No description provided for @ownerInvalidCenterData.
  ///
  /// In en, this message translates to:
  /// **'Please fill all center fields correctly.'**
  String get ownerInvalidCenterData;

  /// No description provided for @ownerCenterAddress.
  ///
  /// In en, this message translates to:
  /// **'Center address'**
  String get ownerCenterAddress;

  /// No description provided for @ownerCenterPcCount.
  ///
  /// In en, this message translates to:
  /// **'PC count'**
  String get ownerCenterPcCount;

  /// No description provided for @ownerCenterPcSpec.
  ///
  /// In en, this message translates to:
  /// **'PC spec'**
  String get ownerCenterPcSpec;

  /// No description provided for @ownerCenterPrice.
  ///
  /// In en, this message translates to:
  /// **'Price per hour'**
  String get ownerCenterPrice;

  /// No description provided for @ownerCenterLatitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get ownerCenterLatitude;

  /// No description provided for @ownerCenterLongitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get ownerCenterLongitude;

  /// No description provided for @ownerCenterProfileImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Center profile image'**
  String get ownerCenterProfileImageLabel;

  /// No description provided for @ownerCenterAddProfileImage.
  ///
  /// In en, this message translates to:
  /// **'Add profile image'**
  String get ownerCenterAddProfileImage;

  /// No description provided for @ownerCenterChangeProfileImage.
  ///
  /// In en, this message translates to:
  /// **'Change profile image'**
  String get ownerCenterChangeProfileImage;

  /// No description provided for @ownerCenterRemoveProfileImage.
  ///
  /// In en, this message translates to:
  /// **'Remove profile image'**
  String get ownerCenterRemoveProfileImage;

  /// No description provided for @ownerCenterGalleryLabel.
  ///
  /// In en, this message translates to:
  /// **'Center gallery images'**
  String get ownerCenterGalleryLabel;

  /// No description provided for @ownerCenterAddImages.
  ///
  /// In en, this message translates to:
  /// **'Add gallery images'**
  String get ownerCenterAddImages;

  /// No description provided for @ownerCenterRemoveSelectedImages.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get ownerCenterRemoveSelectedImages;

  /// No description provided for @ownerCenterImageSelectionHint.
  ///
  /// In en, this message translates to:
  /// **'Long press images to select one or many, then delete them.'**
  String get ownerCenterImageSelectionHint;

  /// No description provided for @ownerCenterImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image.'**
  String get ownerCenterImageFailed;

  /// No description provided for @ownerSeatManagerShort.
  ///
  /// In en, this message translates to:
  /// **'Seat manager'**
  String get ownerSeatManagerShort;

  /// No description provided for @ownerSeatManagerHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a seat to block or unblock it. Booked seats cannot be changed.'**
  String get ownerSeatManagerHint;

  /// No description provided for @ownerSeatPreviewTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking check time'**
  String get ownerSeatPreviewTimeLabel;

  /// No description provided for @ownerSeatPreviewHint.
  ///
  /// In en, this message translates to:
  /// **'Red seats are booked during the selected hour.'**
  String get ownerSeatPreviewHint;

  /// No description provided for @ownerSeatBookingsAtTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookings at {time}'**
  String ownerSeatBookingsAtTimeTitle(Object time);

  /// No description provided for @ownerSeatNoBookingsAtTime.
  ///
  /// In en, this message translates to:
  /// **'No bookings during this time.'**
  String get ownerSeatNoBookingsAtTime;

  /// No description provided for @ownerSeatAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get ownerSeatAvailable;

  /// No description provided for @ownerSeatBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get ownerSeatBlocked;

  /// No description provided for @ownerSeatBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get ownerSeatBooked;

  /// No description provided for @seatSelectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get seatSelectedLabel;

  /// No description provided for @seatUnavailableForTime.
  ///
  /// In en, this message translates to:
  /// **'Unavailable for time'**
  String get seatUnavailableForTime;

  /// No description provided for @ownerSeatManagerTitle.
  ///
  /// In en, this message translates to:
  /// **'Seat Manager - {center}'**
  String ownerSeatManagerTitle(Object center);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'mn'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'mn': return AppLocalizationsMn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
