import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:makernote/config.dart';
import 'package:makernote/plugin/breadcrumb/breadcrumb.wrapper.dart';
import 'package:makernote/services/item/accessibility.service.dart';
import 'package:makernote/services/user.service.dart';
import 'package:makernote/utils/routes.dart';
import 'package:universal_html/html.dart' as html;
import 'package:universal_html/js.dart' as js;
import 'package:beamer/beamer.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide PhoneAuthProvider, EmailAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:firebase_ui_oauth_apple/firebase_ui_oauth_apple.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:makernote/screens/home_location.dart';
import 'package:makernote/services/authentication_service.dart';
import 'package:makernote/services/item/folder_service.dart';
import 'package:makernote/services/item/note_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tflite/tflite.dart';
import 'firebase_options.dart';

const _primaryColor = Color(0xFF2B7C76);
const _brandColor = Color(0xFF53F07A);

CustomColors lightCustomColors = const CustomColors(
  danger: Color(0xFFE53935),
  success: Color(0xFF43A047),
  warning: Color(0xFFFDD835),
  dimmed: Color(0xFF757575),
  onDanger: Color(0xFFFFFFFF),
  onSuccess: Color(0xFFFFFFFF),
  onWarning: Color(0xFF000000),
  onDimmed: Color(0xFF000000),
);
CustomColors darkCustomColors = const CustomColors(
  danger: Color(0xFFEF9A9A),
  success: Color(0xFFA5D6A7),
  warning: Color(0xFFFFF59D),
  dimmed: Color(0xFFBDBDBD),
  onDanger: Color(0xFF000000),
  onSuccess: Color(0xFF000000),
  onWarning: Color(0xFF000000),
  onDimmed: Color(0xFF000000),
);

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    try {
      // FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      // FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
    } catch (e) {
      print(e);
    }
  }

  FirebaseUIAuth.configureProviders([
    EmailAuthProvider(),
    GoogleProvider(clientId: googleClientId),
    AppleProvider(),
  ]);

  // Reset to a larger size if needed
  PaintingBinding.instance.imageCache.maximumSize = 0; // example size
  PaintingBinding.instance.imageCache.maximumSizeBytes =
      0; // example size in bytes (100 MB)

  runApp(
    riverpod.ProviderScope(
        child: MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthenticationService(),
        ),
        Provider(create: (_) => UserService()),
        Provider(create: (_) => FolderService()),
        Provider(create: (_) => NoteService()),
        Provider(create: (_) => AccessibilityService()),
        ChangeNotifierProvider(create: (_) => BreadcrumbWrapper()),
      ],
      child: const MyApp(),
    )),
  );

  // Disable context menu on web
  if (kIsWeb) {
    js.context['oncontextmenu'] = (html.MouseEvent event) {
      event.preventDefault();
    };
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription<User?> user;

  @override
  void initState() {
    super.initState();

    final authService =
        Provider.of<AuthenticationService>(context, listen: false);
    user = authService.userStream.listen((user) {
      if (user == null) {
        debugPrint('User is currently signed out!');
      } else {
        debugPrint('User is signed in!');
      }
      FlutterNativeSplash.remove();
    });
  }

  @override
  void dispose() {
    user.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building MyApp');

    final routerDelegate = BeamerDelegate(
      transitionDelegate: const NoAnimationTransitionDelegate(),
      locationBuilder: (routeInformation, _) => HomeLocation(routeInformation),
      removeDuplicateHistory: true,
      clearBeamingHistoryOn: {
        ...Routes.allRoutes
      }, // Clear history on all routes
    );
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          // On Android S+ devices, use the provided dynamic color scheme.
          // (Recommended) Harmonize the dynamic color scheme' built-in semantic colors.
          lightColorScheme = lightDynamic.harmonized();
          // (Optional) Customize the scheme as desired. For example, one might
          // want to use a brand color to override the dynamic [ColorScheme.secondary].
          lightColorScheme = lightColorScheme.copyWith(secondary: _brandColor);
          // (Optional) If applicable, harmonize custom colors.
          lightCustomColors = lightCustomColors.harmonized(lightColorScheme);

          // Repeat for the dark color scheme.
          darkColorScheme = darkDynamic.harmonized();
          darkColorScheme = darkColorScheme.copyWith(secondary: _brandColor);
          darkCustomColors = darkCustomColors.harmonized(darkColorScheme);
        } else {
          // Otherwise, use fallback schemes.
          lightColorScheme = ColorScheme.fromSeed(
            seedColor: _primaryColor,
          );
          lightColorScheme = lightColorScheme.copyWith(secondary: _brandColor);
          lightCustomColors = lightCustomColors.harmonized(lightColorScheme);

          darkColorScheme = ColorScheme.fromSeed(
            seedColor: _primaryColor,
            brightness: Brightness.dark,
          );
          darkColorScheme = darkColorScheme.copyWith(secondary: _brandColor);
          darkCustomColors = darkCustomColors.harmonized(darkColorScheme);
        }
        return MaterialApp.router(
          title: "Makernote",
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightColorScheme,
            fontFamily: GoogleFonts.merriweatherSans().fontFamily,
            extensions: [lightCustomColors],
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkColorScheme,
            fontFamily: GoogleFonts.merriweatherSans().fontFamily,
            extensions: [darkCustomColors],
          ),
          debugShowCheckedModeBanner: false,
          // showPerformanceOverlay: true,
          routerDelegate: routerDelegate,
          routeInformationParser: BeamerParser(),
          backButtonDispatcher:
              BeamerBackButtonDispatcher(delegate: routerDelegate),
        );
      },
    );
  }
}

@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  const CustomColors({
    required this.danger,
    required this.success,
    required this.warning,
    required this.dimmed,
    required this.onDanger,
    required this.onSuccess,
    required this.onWarning,
    required this.onDimmed,
  });

  final Color? danger;
  final Color? success;
  final Color? warning;
  final Color? dimmed;
  final Color? onDanger;
  final Color? onSuccess;
  final Color? onWarning;
  final Color? onDimmed;

  @override
  CustomColors copyWith({
    Color? danger,
    Color? success,
    Color? warning,
    Color? dimmed,
    Color? onDanger,
    Color? onSuccess,
    Color? onWarning,
    Color? onDimmed,
  }) {
    return CustomColors(
      danger: danger ?? this.danger,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      dimmed: dimmed ?? this.dimmed,
      onDanger: onDanger ?? this.onDanger,
      onSuccess: onSuccess ?? this.onSuccess,
      onWarning: onWarning ?? this.onWarning,
      onDimmed: onDimmed ?? this.onDimmed,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      danger: Color.lerp(danger, other.danger, t),
      success: Color.lerp(success, other.success, t),
      warning: Color.lerp(warning, other.warning, t),
      dimmed: Color.lerp(dimmed, other.dimmed, t),
      onDanger: Color.lerp(onDanger, other.onDanger, t),
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t),
      onWarning: Color.lerp(onWarning, other.onWarning, t),
      onDimmed: Color.lerp(onDimmed, other.onDimmed, t),
    );
  }

  CustomColors harmonized(ColorScheme dynamic) {
    return copyWith(
      danger: danger!.harmonizeWith(dynamic.primary),
      success: success!.harmonizeWith(dynamic.primary),
      warning: warning!.harmonizeWith(dynamic.primary),
      dimmed: dimmed!.harmonizeWith(dynamic.primary),
      onDanger: onDanger!.harmonizeWith(dynamic.onPrimary),
      onSuccess: onSuccess!.harmonizeWith(dynamic.onPrimary),
      onWarning: onWarning!.harmonizeWith(dynamic.onPrimary),
      onDimmed: onDimmed!.harmonizeWith(dynamic.onPrimary),
    );
  }
}
