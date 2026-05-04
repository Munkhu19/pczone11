// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Mongolian (`mn`).
class AppLocalizationsMn extends AppLocalizations {
  AppLocalizationsMn([String locale = 'mn']) : super(locale);

  @override
  String get appTitle => 'E-Sport Төв';

  @override
  String get changeLanguage => 'Хэл солих';

  @override
  String get loginTitle => 'E-SPORT ТӨВ';

  @override
  String get username => 'Нэвтрэх нэр';

  @override
  String get email => 'И-мэйл';

  @override
  String get password => 'Нууц үг';

  @override
  String get confirmPassword => 'Нууц үг давтах';

  @override
  String get signIn => 'Нэвтрэх';

  @override
  String get signUp => 'Бүртгүүлэх';

  @override
  String get switchToSignUp => 'Бүртгэлгүй юу? Бүртгүүлэх';

  @override
  String get switchToSignIn => 'Бүртгэлтэй юу? Нэвтрэх';

  @override
  String get ownerSignUpOption => 'Эзэмшигч хүсэлттэй бүртгүүлэх';

  @override
  String get ownerSignUpHint => 'Энэ нь owner эрхийг шууд нээхгүй. Таны бүртгэл admin зөвшөөрөх хүртэл хүлээгдэж буй төлөвтэй үүснэ.';

  @override
  String get accountCreated => 'Бүртгэл амжилттай үүслээ.';

  @override
  String get usernameAlreadyExists => 'Энэ и-мэйл аль хэдийн бүртгэлтэй байна.';

  @override
  String get passwordsDoNotMatch => 'Нууц үг хоорондоо таарахгүй байна.';

  @override
  String get authInvalidEmail => 'И-мэйл буруу байна.';

  @override
  String get authEmailPasswordNotEnabled => 'Firebase дээр Email/Password нэвтрэх арга идэвхгүй байна.';

  @override
  String get authUserDisabled => 'Энэ бүртгэл идэвхгүй болсон байна.';

  @override
  String get authTooManyRequests => 'Хэт олон оролдлого хийлээ. Түр хүлээгээд дахин оролдоно уу.';

  @override
  String get authApiKeyInvalid => 'Firebase API key энэ апп дээр буруу байна.';

  @override
  String get authFirebaseNotInitialized => 'Firebase инициализаци буруу байна.';

  @override
  String get authWeakPassword => 'Нууц үг хэт сул байна.';

  @override
  String get authNetworkError => 'Сүлжээний алдаа. Интернэтээ шалгана уу.';

  @override
  String get authUnknownError => 'Нэвтрэх үйлдэл амжилтгүй боллоо. Дахин оролдоно уу.';

  @override
  String get login => 'Нэвтрэх';

  @override
  String get invalidCredentials => 'Нэвтрэх нэр эсвэл нууц үг буруу байна';

  @override
  String get centersTitle => 'E-SPORT ТӨВҮҮД';

  @override
  String get homeTab => 'Нүүр';

  @override
  String get searchCenterHint => 'Төв хайх...';

  @override
  String get noCentersFound => 'Төв олдсонгүй';

  @override
  String get mapTitle => 'Төвүүдийн газрын зураг';

  @override
  String get mapTab => 'Газрын зураг';

  @override
  String get bookingHistoryTitle => 'Захиалгын түүх';

  @override
  String addressLabel(Object address) {
    return 'Хаяг: $address';
  }

  @override
  String pcCountLabel(Object count) {
    return 'PC тоо: $count';
  }

  @override
  String pcSpecLabel(Object spec) {
    return 'PC үзүүлэлт: $spec';
  }

  @override
  String pricePerHourLabel(Object price) {
    return 'Үнэ: $price₮ / цаг';
  }

  @override
  String phoneLabel(Object phone) {
    return 'Утас: $phone';
  }

  @override
  String get selectPcSeats => 'PC суудал сонгох';

  @override
  String get makeBooking => 'Захиалга хийх';

  @override
  String selectSeatsTitle(Object center) {
    return 'Суудал сонгох - $center';
  }

  @override
  String get bookingTitle => 'Захиалга';

  @override
  String get fillAllFields => 'Бүх талбарыг бөглөнө үү.';

  @override
  String get selectAtLeastOneSeat => 'Дор хаяж нэг PC суудал сонгоно уу.';

  @override
  String get invalidPlayDuration => 'Тоглох хугацаа 1-ээс их тоо байх ёстой.';

  @override
  String get bookingConfirmed => 'Захиалга баталгаажлаа';

  @override
  String bookingSummary(Object center, Object seats, Object time) {
    return '$center\\nСуудал: $seats\\nЦаг: $time';
  }

  @override
  String get ok => 'Ойлголоо';

  @override
  String get noneSelected => 'Сонгогдоогүй';

  @override
  String centerLabel(Object center) {
    return 'Төв: $center';
  }

  @override
  String selectedSeatsLabel(Object seats) {
    return 'Сонгосон суудал: $seats';
  }

  @override
  String get bookingStartTime => 'Эхлэх цаг';

  @override
  String bookingTimeLabel(Object time) {
    return 'Цаг: $time';
  }

  @override
  String get name => 'Нэр';

  @override
  String get phone => 'Утас';

  @override
  String get phoneMustBe8Digits => 'Утасны дугаар 8 оронтой байх ёстой.';

  @override
  String get playDurationHours => 'Тоглох хугацаа (цаг)';

  @override
  String get invalidStartTime => 'Эхлэх цаг одооноос хойш байх ёстой.';

  @override
  String get confirmBooking => 'Захиалга батлах';

  @override
  String totalPriceLabel(Object price) {
    return 'Нийт: $price₮';
  }

  @override
  String bookingReceipt(Object center, Object seats, Object hours, Object pricePerHour, Object totalPrice) {
    return '$center\\nСуудал: $seats\\nЦаг: $hours\\nЦагийн үнэ: $pricePerHour₮\\nНийт: $totalPrice₮';
  }

  @override
  String get cancelBookingTitle => 'Захиалга цуцлах';

  @override
  String cancelBookingQuestion(Object center) {
    return '$center төвийн захиалгыг цуцлах уу?';
  }

  @override
  String get no => 'Үгүй';

  @override
  String get yesCancel => 'Тийм, цуцлах';

  @override
  String get bookingCanceled => 'Захиалга цуцлагдлаа.';

  @override
  String get bookingAlreadyCanceled => 'Энэ захиалга өмнө нь цуцлагдсан байна.';

  @override
  String get clearCanceledBookingsTitle => 'Цуцлагдсан захиалгууд цэвэрлэх';

  @override
  String get clearCanceledBookingsMessage => 'Түүхээсээ бүх цуцлагдсан захиалгыг устгах уу?';

  @override
  String get clearCanceledBookingsAction => 'Цуцлагдсаныг цэвэрлэх';

  @override
  String get canceledBookingsCleared => 'Цуцлагдсан захиалгууд цэвэрлэгдлээ.';

  @override
  String get noBookingHistory => 'Захиалгын түүх хоосон байна.';

  @override
  String get statusCanceled => 'Цуцлагдсан';

  @override
  String get statusActive => 'Идэвхтэй';

  @override
  String customerLabel(Object name) {
    return 'Захиалагч: $name';
  }

  @override
  String durationLabel(Object hours) {
    return 'Хугацаа: $hours цаг';
  }

  @override
  String seatsLabel(Object seats) {
    return 'Суудал: $seats';
  }

  @override
  String createdLabel(Object date) {
    return 'Үүсгэсэн: $date';
  }

  @override
  String canceledLabel(Object date) {
    return 'Цуцалсан: $date';
  }

  @override
  String get cancelBookingAction => 'Захиалга цуцлах';

  @override
  String get profileTitle => 'Профайл';

  @override
  String get profileNotSignedIn => 'Нэвтрээгүй байна';

  @override
  String get profileNoDisplayName => 'Харуулах нэр оноогоүй';

  @override
  String profileUidLabel(Object uid) {
    return 'UID: $uid';
  }

  @override
  String get profileDisplayNameLabel => 'Харуулах нэр';

  @override
  String get profileSaveButton => 'Профайл хадгалах';

  @override
  String get profileAvatarUpload => 'Аватар оруулах';

  @override
  String get profileAvatarUpdated => 'Аватар амжилттай шинэчлэгдлээ';

  @override
  String get profileAvatarUpdateFailed => 'Аватар оруулахад алдаа гарлаа';

  @override
  String get profileUpdated => 'Профайл амжилттай шинэчлэгдлээ';

  @override
  String get profileUpdateFailed => 'Профайл шинэчлэхэд алдаа гарлаа';

  @override
  String get profileAccountSection => 'Бүртгэл';

  @override
  String get profileEditSection => 'Профайл засах';

  @override
  String get profileActivitySection => 'Бүртгэлийн идэвх';

  @override
  String get profileSettingsTitle => 'Профайлын тохиргоо';

  @override
  String get profileRoleLabel => 'Төрөл';

  @override
  String get profileUidTitle => 'UID';

  @override
  String get profileCreatedAtLabel => 'Бүртгүүлсэн огноо';

  @override
  String get profileLastSignInTitle => 'Сүүлд нэвтэрсэн';

  @override
  String get profileCopyAction => 'Хуулах';

  @override
  String get profileEmailCopied => 'И-мэйл хуулагдлаа';

  @override
  String get profileUidCopied => 'UID хуулагдлаа';

  @override
  String get profileChangePassword => 'Нууц үг солих';

  @override
  String profilePasswordResetSent(Object email) {
    return '$email хаяг руу нууц үг сэргээх мэйл илгээгдлээ';
  }

  @override
  String get profileEmailVerificationTitle => 'И-мэйл баталгаажуулалт';

  @override
  String get profileEmailVerified => 'Баталгаажсан';

  @override
  String get profileEmailNotVerified => 'Баталгаажаагүй';

  @override
  String get profileSendVerification => 'Баталгаажуулах мэйл илгээх';

  @override
  String get profileRefreshVerification => 'Сэргээх';

  @override
  String profileVerificationSent(Object email) {
    return '$email хаяг руу баталгаажуулах мэйл илгээгдлээ';
  }

  @override
  String get logout => 'Гарах';

  @override
  String profileLastSignInLabel(Object date) {
    return 'Сүүлд нэвтэрсэн: $date';
  }

  @override
  String get ownerRoleCustomer => 'Хэрэглэгч';

  @override
  String get adminRoleLabel => 'Админ';

  @override
  String get ownerRolePending => 'Эзэмшигч хүлээгдэж буй';

  @override
  String get ownerRoleOwner => 'Эзэмшигч';

  @override
  String get ownerApplyTitle => 'Эзэмшигч болох хүсэлт';

  @override
  String get ownerApplyMessage => 'Эзэмшигч болох хүсэлт илгээх үү? Зөвшөөрөгдөх хүртэл owner эрх нээгдэхгүй.';

  @override
  String get ownerApplyAction => 'Эзэмшигч болох хүсэлт';

  @override
  String get ownerApplySubmitted => 'Эзэмшигчийн хүсэлт илгээгдлээ. Зөвшөөрөл хүлээнэ үү.';

  @override
  String get ownerApplicationFormTitle => 'Эзэмшигчийн хүсэлтийн маягт';

  @override
  String get ownerApplicationFormSubtitle => 'Төвийнхөө мэдээллийг бөглөж админд илгээнэ үү.';

  @override
  String get ownerApplicationCenterName => 'Төвийн нэр';

  @override
  String get ownerApplicationPhone => 'Холбоо барих утас';

  @override
  String get ownerApplicationAddress => 'Төвийн хаяг';

  @override
  String get ownerApplicationLink => 'Facebook хуудас эсвэл Google Maps холбоос';

  @override
  String get ownerApplicationNote => 'Нэмэлт тайлбар';

  @override
  String get ownerApplicationSubmit => 'Хүсэлт илгээх';

  @override
  String get ownerApplicationRequiredFields => 'Төвийн нэр, утас, хаягийг заавал бөглөнө үү.';

  @override
  String get ownerPendingTitle => 'Эзэмшигчийн хүсэлт хүлээгдэж байна';

  @override
  String get ownerPendingHeading => 'Таны эзэмшигчийн хүсэлт шалгагдаж байна';

  @override
  String get ownerPendingMessage => 'Таны хүсэлтийг хүлээн авлаа. Зөвшөөрөгдсөний дараа эзэмшигчийн эрх нээгдэнэ.';

  @override
  String get ownerPendingInline => 'Таны эзэмшигчийн хүсэлт илгээгдсэн бөгөөд зөвшөөрөл хүлээж байна.';

  @override
  String get adminDashboardTitle => 'Админы хянах самбар';

  @override
  String get adminCentersTitle => 'Бүх төвүүд';

  @override
  String get adminUsersTitle => 'Хэрэглэгчид';

  @override
  String get adminUsersEmpty => 'Хэрэглэгч олдсонгүй.';

  @override
  String get adminPendingRequests => 'Хүлээгдэж буй хүсэлтүүд';

  @override
  String get adminOwnersCount => 'Эзэмшигчид';

  @override
  String get adminCustomersCount => 'Хэрэглэгчид';

  @override
  String get adminAdminsCount => 'Админууд';

  @override
  String get adminCentersCount => 'Төвүүд';

  @override
  String get adminBookingsCount => 'Захиалгууд';

  @override
  String get adminRevenueTotal => 'Нийт орлого';

  @override
  String get ownerRequestsTitle => 'Эзэмшигчийн хүсэлтүүд';

  @override
  String get ownerRequestsEmpty => 'Хүлээгдэж буй эзэмшигчийн хүсэлт алга.';

  @override
  String get ownerApproveAction => 'Зөвшөөрөх';

  @override
  String get ownerRejectAction => 'Татгалзах';

  @override
  String ownerRequestApproved(Object email) {
    return '$email хаягийн owner хүсэлтийг зөвшөөрлөө';
  }

  @override
  String ownerRequestRejected(Object email) {
    return '$email хаягийн owner хүсэлтийг татгалзлаа';
  }

  @override
  String get adminDeleteUserTitle => 'Хэрэглэгчийн өгөгдөл устгах';

  @override
  String adminDeleteUserMessage(Object email) {
    return '$email хаягийн app доторх бүх өгөгдлийг устгах уу? Firebase Authentication дээрх хэрэглэгчийг тусад нь устгана.';
  }

  @override
  String get adminDeleteUserAction => 'Өгөгдөл устгах';

  @override
  String get adminDeleteUserProtected => 'Хамгаалагдсан админ бүртгэл';

  @override
  String adminUserDeleted(Object email) {
    return '$email хаягийн app өгөгдөл устлаа.';
  }

  @override
  String get adminSetAsOwner => 'Эзэмшигч болгох';

  @override
  String get adminSetAsCustomer => 'Хэрэглэгч болгох';

  @override
  String adminUserPromotedOwner(Object email) {
    return '$email хаягийг эзэмшигч болголоо.';
  }

  @override
  String adminUserSetCustomer(Object email) {
    return '$email хаягийг хэрэглэгч болголоо.';
  }

  @override
  String get ownerDashboardTitle => 'Эзэмшигчийн хянах самбар';

  @override
  String get ownerCentersTitle => 'Миний төвүүд';

  @override
  String get ownerBookingsTitle => 'Төвийн захиалгууд';

  @override
  String get ownerCentersCount => 'Эзэмшдэг төвүүд';

  @override
  String get ownerBookingsCount => 'Захиалгын тоо';

  @override
  String get ownerRevenueTotal => 'Нийт орлого';

  @override
  String get ownerOccupiedSeats => 'Дүүрсэн суудал';

  @override
  String get ownerRecentBookings => 'Сүүлийн захиалгууд';

  @override
  String get ownerNoBookings => 'Таны төвүүд дээр одоогоор захиалга алга.';

  @override
  String get ownerNoBookingsForFilter => 'Энэ шүүлтүүрт тохирох захиалга алга.';

  @override
  String get ownerClearBookingsTitle => 'Цуцлагдсан захиалгууд цэвэрлэх';

  @override
  String get ownerClearBookingsMessage => 'Өөрийн төвүүдийн цуцлагдсан захиалгуудыг цэвэрлэх үү?';

  @override
  String get ownerClearBookingsAction => 'Цуцлагдсаныг цэвэрлэх';

  @override
  String get ownerBookingsCleared => 'Цуцлагдсан захиалгууд цэвэрлэгдлээ.';

  @override
  String get ownerFilterAll => 'Бүгд';

  @override
  String get ownerNoCenters => 'Та одоогоор төв эзэмшдэггүй байна.';

  @override
  String get ownerAddCenter => 'Төв нэмэх';

  @override
  String get ownerEditCenter => 'Төв засах';

  @override
  String get ownerSaveCenter => 'Төв хадгалах';

  @override
  String get ownerDeleteCenterTitle => 'Төв устгах';

  @override
  String ownerDeleteCenterMessage(Object center) {
    return '$center төвийг бүр мөсөн устгах уу? Үүнтэй холбоотой захиалга болон суудлын төлөвүүд бас устна.';
  }

  @override
  String get ownerDeleteCenterAction => 'Төв устгах';

  @override
  String ownerCenterDeleted(Object center) {
    return '$center төв устлаа.';
  }

  @override
  String get ownerInvalidCenterData => 'Төвийн мэдээллээ зөв бөглөнө үү.';

  @override
  String get ownerCenterAddress => 'Төвийн хаяг';

  @override
  String get ownerCenterPcCount => 'PC тоо';

  @override
  String get ownerCenterPcSpec => 'PC үзүүлэлт';

  @override
  String get ownerCenterPrice => 'Цагийн үнэ';

  @override
  String get ownerCenterLatitude => 'Өргөрөг';

  @override
  String get ownerCenterLongitude => 'Уртраг';

  @override
  String get ownerCenterProfileImageLabel => 'Төвийн profile зураг';

  @override
  String get ownerCenterAddProfileImage => 'Profile зураг нэмэх';

  @override
  String get ownerCenterChangeProfileImage => 'Profile зураг солих';

  @override
  String get ownerCenterRemoveProfileImage => 'Profile зураг устгах';

  @override
  String get ownerCenterGalleryLabel => 'Төвийн мэдээллийн зургууд';

  @override
  String get ownerCenterAddImages => 'Мэдээллийн зураг нэмэх';

  @override
  String get ownerCenterRemoveSelectedImages => 'Сонгосныг устгах';

  @override
  String get ownerCenterImageSelectionHint => 'Зурган дээр удаан дарж нэг эсвэл олныг сонгоод устгаж болно.';

  @override
  String get ownerCenterImageFailed => 'Зураг сонгоход алдаа гарлаа.';

  @override
  String get ownerSeatManagerShort => 'Суудал';

  @override
  String get ownerSeatManagerHint => 'Суудал дээр дарж хаах эсвэл нээж болно. Захиалгатай суудлыг өөрчлөхгүй.';

  @override
  String get ownerSeatPreviewTimeLabel => 'Захиалга шалгах цаг';

  @override
  String get ownerSeatPreviewHint => 'Сонгосон 1 цагийн дотор захиалгатай суудал улаанаар харагдана.';

  @override
  String ownerSeatBookingsAtTimeTitle(Object time) {
    return '$time цагийн захиалгууд';
  }

  @override
  String get ownerSeatNoBookingsAtTime => 'Энэ цагт захиалга алга.';

  @override
  String get ownerSeatAvailable => 'Нээлттэй';

  @override
  String get ownerSeatBlocked => 'Хаалттай';

  @override
  String get ownerSeatBooked => 'Захиалгатай';

  @override
  String get seatSelectedLabel => 'Сонгосон';

  @override
  String get seatUnavailableForTime => 'Энэ цагт завгүй';

  @override
  String ownerSeatManagerTitle(Object center) {
    return 'Суудлын удирдлага - $center';
  }
}
