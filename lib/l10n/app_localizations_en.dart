// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'E-Sport Center';

  @override
  String get changeLanguage => 'Change language';

  @override
  String get loginTitle => 'E-SPORT CENTER';

  @override
  String get username => 'Username';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Sign up';

  @override
  String get switchToSignUp => 'Don\'t have an account? Sign up';

  @override
  String get switchToSignIn => 'Already have an account? Sign in';

  @override
  String get ownerSignUpOption => 'Register with owner request';

  @override
  String get ownerSignUpHint => 'This does not create an owner account immediately. Your account will be created as pending until admin approval.';

  @override
  String get accountCreated => 'Account created successfully.';

  @override
  String get usernameAlreadyExists => 'This email is already in use.';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get authInvalidEmail => 'Invalid email address.';

  @override
  String get authEmailPasswordNotEnabled => 'Email/Password sign-in is disabled in Firebase.';

  @override
  String get authUserDisabled => 'This account has been disabled.';

  @override
  String get authTooManyRequests => 'Too many attempts. Try again later.';

  @override
  String get authApiKeyInvalid => 'Firebase API key is invalid for this app.';

  @override
  String get authFirebaseNotInitialized => 'Firebase is not initialized correctly.';

  @override
  String get authWeakPassword => 'Password is too weak.';

  @override
  String get authNetworkError => 'Network error. Please check your internet.';

  @override
  String get authUnknownError => 'Authentication failed. Please try again.';

  @override
  String get login => 'Login';

  @override
  String get invalidCredentials => 'Invalid username or password';

  @override
  String get centersTitle => 'E-SPORT CENTERS';

  @override
  String get homeTab => 'Home';

  @override
  String get searchCenterHint => 'Search center...';

  @override
  String get noCentersFound => 'No centers found';

  @override
  String get mapTitle => 'Center Map';

  @override
  String get mapTab => 'Map';

  @override
  String get bookingHistoryTitle => 'Booking History';

  @override
  String addressLabel(Object address) {
    return 'Address: $address';
  }

  @override
  String pcCountLabel(Object count) {
    return 'PC count: $count';
  }

  @override
  String pcSpecLabel(Object spec) {
    return 'PC spec: $spec';
  }

  @override
  String pricePerHourLabel(Object price) {
    return 'Price: $price₮ / hour';
  }

  @override
  String phoneLabel(Object phone) {
    return 'Phone: $phone';
  }

  @override
  String get selectPcSeats => 'Select PC Seats';

  @override
  String get makeBooking => 'Make Booking';

  @override
  String selectSeatsTitle(Object center) {
    return 'Select Seats - $center';
  }

  @override
  String get bookingTitle => 'Booking';

  @override
  String get fillAllFields => 'Please fill all fields.';

  @override
  String get selectAtLeastOneSeat => 'Please select at least one PC seat.';

  @override
  String get invalidPlayDuration => 'Play duration must be a positive number.';

  @override
  String get bookingConfirmed => 'Booking Confirmed';

  @override
  String bookingSummary(Object center, Object seats, Object time) {
    return '$center\\nSeats: $seats\\nTime: $time';
  }

  @override
  String get ok => 'OK';

  @override
  String get noneSelected => 'None';

  @override
  String centerLabel(Object center) {
    return 'Center: $center';
  }

  @override
  String selectedSeatsLabel(Object seats) {
    return 'Selected seats: $seats';
  }

  @override
  String get bookingStartTime => 'Start time';

  @override
  String bookingTimeLabel(Object time) {
    return 'Time: $time';
  }

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone';

  @override
  String get phoneMustBe8Digits => 'Phone number must be exactly 8 digits.';

  @override
  String get playDurationHours => 'Play duration (hours)';

  @override
  String get invalidStartTime => 'Start time must be in the future.';

  @override
  String get confirmBooking => 'Confirm Booking';

  @override
  String totalPriceLabel(Object price) {
    return 'Total: $price₮';
  }

  @override
  String bookingReceipt(Object center, Object seats, Object hours, Object pricePerHour, Object totalPrice) {
    return '$center\\nSeats: $seats\\nHours: $hours\\nPrice/hour: $pricePerHour₮\\nTotal: $totalPrice₮';
  }

  @override
  String get cancelBookingTitle => 'Cancel Booking';

  @override
  String cancelBookingQuestion(Object center) {
    return 'Cancel booking for $center?';
  }

  @override
  String get no => 'No';

  @override
  String get yesCancel => 'Yes, cancel';

  @override
  String get bookingCanceled => 'Booking canceled.';

  @override
  String get bookingAlreadyCanceled => 'Booking already canceled.';

  @override
  String get clearCanceledBookingsTitle => 'Clear canceled bookings';

  @override
  String get clearCanceledBookingsMessage => 'Remove all canceled bookings from your history?';

  @override
  String get clearCanceledBookingsAction => 'Clear canceled';

  @override
  String get canceledBookingsCleared => 'Canceled bookings cleared.';

  @override
  String get noBookingHistory => 'No booking history yet.';

  @override
  String get statusCanceled => 'Canceled';

  @override
  String get statusActive => 'Active';

  @override
  String customerLabel(Object name) {
    return 'Customer: $name';
  }

  @override
  String durationLabel(Object hours) {
    return 'Duration: $hours hour(s)';
  }

  @override
  String seatsLabel(Object seats) {
    return 'Seats: $seats';
  }

  @override
  String createdLabel(Object date) {
    return 'Created: $date';
  }

  @override
  String canceledLabel(Object date) {
    return 'Canceled: $date';
  }

  @override
  String get cancelBookingAction => 'Cancel Booking';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileNotSignedIn => 'Not signed in';

  @override
  String get profileNoDisplayName => 'No display name';

  @override
  String profileUidLabel(Object uid) {
    return 'UID: $uid';
  }

  @override
  String get profileDisplayNameLabel => 'Display name';

  @override
  String get profileSaveButton => 'Save profile';

  @override
  String get profileAvatarUpload => 'Upload avatar';

  @override
  String get profileAvatarUpdated => 'Avatar updated';

  @override
  String get profileAvatarUpdateFailed => 'Failed to upload avatar';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get profileUpdateFailed => 'Failed to update profile';

  @override
  String get profileAccountSection => 'Account';

  @override
  String get profileEditSection => 'Edit profile';

  @override
  String get profileActivitySection => 'Account activity';

  @override
  String get profileSettingsTitle => 'Profile settings';

  @override
  String get profileRoleLabel => 'Role';

  @override
  String get profileUidTitle => 'UID';

  @override
  String get profileCreatedAtLabel => 'Created at';

  @override
  String get profileLastSignInTitle => 'Last sign-in';

  @override
  String get profileCopyAction => 'Copy';

  @override
  String get profileEmailCopied => 'Email copied';

  @override
  String get profileUidCopied => 'UID copied';

  @override
  String get profileChangePassword => 'Change password';

  @override
  String profilePasswordResetSent(Object email) {
    return 'Password reset email sent to $email';
  }

  @override
  String get profileEmailVerificationTitle => 'Email verification';

  @override
  String get profileEmailVerified => 'Verified';

  @override
  String get profileEmailNotVerified => 'Not verified';

  @override
  String get profileSendVerification => 'Send verification';

  @override
  String get profileRefreshVerification => 'Refresh';

  @override
  String profileVerificationSent(Object email) {
    return 'Verification email sent to $email';
  }

  @override
  String get logout => 'Log out';

  @override
  String profileLastSignInLabel(Object date) {
    return 'Last sign-in: $date';
  }

  @override
  String get ownerRoleCustomer => 'Customer';

  @override
  String get adminRoleLabel => 'Admin';

  @override
  String get ownerRolePending => 'Owner pending';

  @override
  String get ownerRoleOwner => 'Owner';

  @override
  String get ownerApplyTitle => 'Apply as owner';

  @override
  String get ownerApplyMessage => 'Send a request to become an owner? Until approval, you will not have owner access.';

  @override
  String get ownerApplyAction => 'Apply as owner';

  @override
  String get ownerApplySubmitted => 'Owner request submitted. Please wait for approval.';

  @override
  String get ownerApplicationFormTitle => 'Owner application';

  @override
  String get ownerApplicationFormSubtitle => 'Submit your center details for admin review.';

  @override
  String get ownerApplicationCenterName => 'Center name';

  @override
  String get ownerApplicationPhone => 'Contact phone';

  @override
  String get ownerApplicationAddress => 'Center address';

  @override
  String get ownerApplicationLink => 'Facebook page or Google Maps link';

  @override
  String get ownerApplicationNote => 'Additional note';

  @override
  String get ownerApplicationSubmit => 'Submit owner request';

  @override
  String get ownerApplicationRequiredFields => 'Please fill center name, phone, and address.';

  @override
  String get ownerPendingTitle => 'Owner request pending';

  @override
  String get ownerPendingHeading => 'Your owner request is under review';

  @override
  String get ownerPendingMessage => 'We received your request. You will get owner access after approval.';

  @override
  String get ownerPendingInline => 'Your owner request has been submitted and is waiting for approval.';

  @override
  String get adminDashboardTitle => 'Admin Dashboard';

  @override
  String get adminCentersTitle => 'All Centers';

  @override
  String get adminUsersTitle => 'Users';

  @override
  String get adminUsersEmpty => 'No users found.';

  @override
  String get adminPendingRequests => 'Pending requests';

  @override
  String get adminOwnersCount => 'Owners';

  @override
  String get adminCustomersCount => 'Customers';

  @override
  String get adminAdminsCount => 'Admins';

  @override
  String get adminCentersCount => 'Centers';

  @override
  String get adminBookingsCount => 'Bookings';

  @override
  String get adminRevenueTotal => 'Revenue';

  @override
  String get ownerRequestsTitle => 'Owner requests';

  @override
  String get ownerRequestsEmpty => 'No pending owner requests.';

  @override
  String get ownerApproveAction => 'Approve';

  @override
  String get ownerRejectAction => 'Reject';

  @override
  String ownerRequestApproved(Object email) {
    return 'Approved owner request for $email';
  }

  @override
  String ownerRequestRejected(Object email) {
    return 'Rejected owner request for $email';
  }

  @override
  String get adminDeleteUserTitle => 'Delete user data';

  @override
  String adminDeleteUserMessage(Object email) {
    return 'Delete all app data for $email? Firebase Authentication user deletion still needs to be done separately.';
  }

  @override
  String get adminDeleteUserAction => 'Delete user data';

  @override
  String get adminDeleteUserProtected => 'Protected admin account';

  @override
  String adminUserDeleted(Object email) {
    return 'App data deleted for $email.';
  }

  @override
  String get adminSetAsOwner => 'Set as owner';

  @override
  String get adminSetAsCustomer => 'Set as customer';

  @override
  String adminUserPromotedOwner(Object email) {
    return '$email is now an owner.';
  }

  @override
  String adminUserSetCustomer(Object email) {
    return '$email is now a customer.';
  }

  @override
  String get ownerDashboardTitle => 'Owner Dashboard';

  @override
  String get ownerCentersTitle => 'My Centers';

  @override
  String get ownerBookingsTitle => 'Center Bookings';

  @override
  String get ownerCentersCount => 'Owned centers';

  @override
  String get ownerBookingsCount => 'Bookings';

  @override
  String get ownerRevenueTotal => 'Revenue';

  @override
  String get ownerOccupiedSeats => 'Occupied seats';

  @override
  String get ownerRecentBookings => 'Recent bookings';

  @override
  String get ownerNoBookings => 'No bookings for your centers yet.';

  @override
  String get ownerNoBookingsForFilter => 'No bookings match this filter.';

  @override
  String get ownerClearBookingsTitle => 'Clear canceled bookings';

  @override
  String get ownerClearBookingsMessage => 'Clear canceled bookings for your centers?';

  @override
  String get ownerClearBookingsAction => 'Clear canceled';

  @override
  String get ownerBookingsCleared => 'Canceled bookings cleared.';

  @override
  String get ownerFilterAll => 'All';

  @override
  String get ownerNoCenters => 'You do not own any centers yet.';

  @override
  String get ownerAddCenter => 'Add center';

  @override
  String get ownerEditCenter => 'Edit center';

  @override
  String get ownerSaveCenter => 'Save center';

  @override
  String get ownerDeleteCenterTitle => 'Delete center';

  @override
  String ownerDeleteCenterMessage(Object center) {
    return 'Delete $center completely? This will also remove its bookings and seat states.';
  }

  @override
  String get ownerDeleteCenterAction => 'Delete center';

  @override
  String ownerCenterDeleted(Object center) {
    return '$center deleted.';
  }

  @override
  String get ownerInvalidCenterData => 'Please fill all center fields correctly.';

  @override
  String get ownerCenterAddress => 'Center address';

  @override
  String get ownerCenterPcCount => 'PC count';

  @override
  String get ownerCenterPcSpec => 'PC spec';

  @override
  String get ownerCenterPrice => 'Price per hour';

  @override
  String get ownerCenterLatitude => 'Latitude';

  @override
  String get ownerCenterLongitude => 'Longitude';

  @override
  String get ownerCenterProfileImageLabel => 'Center profile image';

  @override
  String get ownerCenterAddProfileImage => 'Add profile image';

  @override
  String get ownerCenterChangeProfileImage => 'Change profile image';

  @override
  String get ownerCenterRemoveProfileImage => 'Remove profile image';

  @override
  String get ownerCenterGalleryLabel => 'Center gallery images';

  @override
  String get ownerCenterAddImages => 'Add gallery images';

  @override
  String get ownerCenterRemoveSelectedImages => 'Delete selected';

  @override
  String get ownerCenterImageSelectionHint => 'Long press images to select one or many, then delete them.';

  @override
  String get ownerCenterImageFailed => 'Failed to pick image.';

  @override
  String get ownerSeatManagerShort => 'Seat manager';

  @override
  String get ownerSeatManagerHint => 'Tap a seat to block or unblock it. Booked seats cannot be changed.';

  @override
  String get ownerSeatPreviewTimeLabel => 'Booking check time';

  @override
  String get ownerSeatPreviewHint => 'Red seats are booked during the selected hour.';

  @override
  String ownerSeatBookingsAtTimeTitle(Object time) {
    return 'Bookings at $time';
  }

  @override
  String get ownerSeatNoBookingsAtTime => 'No bookings during this time.';

  @override
  String get ownerSeatAvailable => 'Available';

  @override
  String get ownerSeatBlocked => 'Blocked';

  @override
  String get ownerSeatBooked => 'Booked';

  @override
  String get seatSelectedLabel => 'Selected';

  @override
  String get seatUnavailableForTime => 'Unavailable for time';

  @override
  String ownerSeatManagerTitle(Object center) {
    return 'Seat Manager - $center';
  }
}
