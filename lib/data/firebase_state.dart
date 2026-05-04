import 'package:flutter/foundation.dart';

bool firebaseAvailable = false;
final ValueNotifier<bool> authFlowInProgress = ValueNotifier<bool>(false);
