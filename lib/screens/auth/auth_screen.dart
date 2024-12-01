import 'package:beamer/beamer.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:makernote/services/authentication_service.dart';
import 'package:makernote/utils/routes.dart';
import 'package:makernote/widgets/legal_info.dart';
import 'package:makernote/widgets/logo.dart';
import 'package:provider/provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _controller?.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          constraints: const BoxConstraints.expand(),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    const Logo(
                      size: 100,
                    ),
                    // app name
                    Text(
                      "Welcome to Makernote",
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 40, right: 40, top: 20),
                  child: FirebaseUIActions(
                    actions: [
                      AuthStateChangeAction<SignedIn>((context, state) {
                        // redirect to other screen
                        context.beamToReplacementNamed(Routes.homeScreen);

                        if (state.user != null) {
                          final authService =
                              Provider.of<AuthenticationService>(context,
                                  listen: false);
                          authService.onSignedUp(state.user!);
                        }
                      }),
                      AuthStateChangeAction<UserCreated>((context, state) {
                        // redirect to other screen
                        context.beamToReplacementNamed(Routes.homeScreen);

                        // add user to database
                        final authService = Provider.of<AuthenticationService>(
                            context,
                            listen: false);
                        if (state.credential.user != null) {
                          authService.onSignedUp(state.credential.user!);
                        }
                      })
                    ],
                    child: Card(
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 100),
                        curve: Curves.easeInOut,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          alignment: Alignment.center,
                          constraints: const BoxConstraints(
                            maxWidth: 400,
                          ),
                          child: LoginView(
                            action: AuthAction.signIn,
                            showPasswordVisibilityToggle: true,
                            providers: [
                              ...FirebaseUIAuth.providersFor(
                                firebase.FirebaseAuth.instance.app,
                              )
                            ],
                            footerBuilder: (context, action) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: Text(
                                  "By signing in, you agree to our terms and conditions.",
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // legal info
                const LegalInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
