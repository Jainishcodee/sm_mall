import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  GoogleFonts.config.allowRuntimeFetching = true;
  runApp(const ProviderScope(child: MallDashApp()));

  // Fire-and-forget — push notifications are non-critical; never let them
  // delay the first frame or crash startup.
  // ignore: discarded_futures
  PushNotificationService.instance.initialize();
}
