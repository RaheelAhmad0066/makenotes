import 'dart:async';
import 'dart:math';

import 'package:filesize/filesize.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:makernote/main.dart';
import 'package:makernote/services/authentication_service.dart';
import 'package:makernote/services/item/note_service.dart';
import 'package:makernote/utils/colors.dart';
import 'package:makernote/utils/helpers/promo.helper.dart';
import 'package:makernote/utils/helpers/user.helper.dart';
import 'package:makernote/widgets/flex.extension.dart';
import 'package:makernote/widgets/legal_info.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountScreen extends HookWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final itemService = Provider.of<NoteService>(context);
    final lastFetchTime = useState<DateTime>(DateTime.now());

    final usageFuture = useFuture(
      useMemoized(() {
        return itemService.getUsage();
      }, [lastFetchTime.value]),
    );

    double screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FlexWithExtension.withSpacing(
          direction: Axis.vertical,
          spacing: 16,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // screen title
            Text(
              "Account",
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            FlexWithExtension.withSpacing(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              direction: screenWidth > 600 ? Axis.horizontal : Axis.vertical,
              spacing: 16,
              children: [
                // account info
                Flexible(
                  flex: 1,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: FlexWithExtension.withSpacing(
                        direction: Axis.vertical,
                        spacing: 8,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // account info title
                          Text(
                            "Account Info",
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),

                          Consumer<AuthenticationService>(
                            builder: (context, authService, child) {
                              return StreamBuilder(
                                stream: authService.userStream,
                                builder: (context, snapshot) {
                                  final user = snapshot.data;
                                  return FlexWithExtension.withSpacing(
                                    direction: Axis.vertical,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    spacing: 16,
                                    children: [
                                      // user avatar
                                      Stack(
                                        children: [
                                          user?.photoURL != null
                                              ? CircleAvatar(
                                                  radius: IconTheme.of(context)
                                                          .size! *
                                                      2,
                                                  backgroundImage: NetworkImage(
                                                    user!.photoURL!,
                                                  ),
                                                )
                                              : CircleAvatar(
                                                  radius: IconTheme.of(context)
                                                          .size! *
                                                      2,
                                                  child: Icon(
                                                    Icons.person,
                                                    size: IconTheme.of(context)
                                                            .size! *
                                                        2,
                                                  ),
                                                ),

                                          // edit avatar button
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: IconButton.filledTonal(
                                              icon: const Icon(Icons.edit),
                                              onPressed: () async {
                                                await updateUserPhotoUrl(
                                                  context: context,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),

                                      // user name
                                      FlexWithExtension.withSpacing(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        direction: Axis.vertical,
                                        spacing: 8,
                                        children: [
                                          Text(
                                            'Name',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.6),
                                                ),
                                          ),
                                          Text(
                                            user?.displayName ?? "",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                          ),

                                          // edit name button
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: user != null
                                                ? () async {
                                                    await showUpdateDisplayNameDialog(
                                                        context: context,
                                                        displayName:
                                                            user.displayName);
                                                  }
                                                : null,
                                          ),
                                        ],
                                      ),

                                      // user email
                                      FlexWithExtension.withSpacing(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        direction: Axis.vertical,
                                        spacing: 8,
                                        children: [
                                          Text(
                                            'Email',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.6),
                                                ),
                                          ),
                                          Text(
                                            user?.email ?? "---",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.6),
                                                ),
                                          ),
                                          // is email verified
                                          if (user?.emailVerified != null) ...[
                                            // send verification email button
                                            if (!user!.emailVerified)
                                              ElevatedButton.icon(
                                                onPressed: () async {
                                                  await user
                                                      .sendEmailVerification();
                                                },
                                                icon: const Icon(Icons.send),
                                                label: const Text(
                                                    "Send Verification Email"),
                                              ),
                                          ],
                                        ],
                                      ),

                                      if (kDebugMode) ...[
                                        // user id
                                        FlexWithExtension.withSpacing(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          direction: Axis.vertical,
                                          spacing: 8,
                                          children: [
                                            Text(
                                              'User ID',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.6),
                                                  ),
                                            ),
                                            Text(
                                              user?.uid ?? "---",
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.6),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],

                                      // user phone number
                                      if (user?.phoneNumber != null) ...[
                                        FlexWithExtension.withSpacing(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          direction: Axis.vertical,
                                          spacing: 8,
                                          children: [
                                            Text(
                                              'Phone Number',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.6),
                                                  ),
                                            ),
                                            Text(
                                              user?.phoneNumber ?? "---",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.6),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],

                                      // user creation date
                                      if (user?.metadata.creationTime !=
                                          null) ...[
                                        FlexWithExtension.withSpacing(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          direction: Axis.vertical,
                                          spacing: 8,
                                          children: [
                                            Text(
                                              'Created At',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.6),
                                                  ),
                                            ),
                                            Text(
                                              DateFormat.yMMMMd().format(
                                                user!.metadata.creationTime!,
                                              ),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.6),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],

                                      const Divider(),

                                      // actions
                                      ...[
                                        // sign out button
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            final authService = Provider.of<
                                                    AuthenticationService>(
                                                context,
                                                listen: false);
                                            authService.signOut();
                                          },
                                          icon: const Icon(Icons.logout),
                                          label: const Text("Sign Out"),
                                        ),

                                        // reset password button
                                        ResetPasswordButton(
                                          disabled: user?.emailVerified != true,
                                          email: user?.email,
                                        ),

                                        // delete account button
                                        const DeleteAccountButton(),
                                      ],
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // usage info
                Flexible(
                  flex: 1,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: FlexWithExtension.withSpacing(
                        direction: Axis.vertical,
                        spacing: 8,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // usage info title
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Storage Usage",
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),

                              // refresh button
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: () {
                                  lastFetchTime.value = DateTime.now();
                                },
                              ),
                            ],
                          ),

                          // item usage info
                          FlexWithExtension.withSpacing(
                            direction: Axis.vertical,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 8,
                            children: [
                              // item usage info title
                              Row(
                                children: [
                                  Text(
                                    "Items Usage",
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  ),
                                  // more info tooltip
                                  Tooltip(
                                    richMessage: const TextSpan(
                                      children: [
                                        TextSpan(
                                          text:
                                              "Items are notes, folders, and other items that you create.",
                                        ),
                                        TextSpan(
                                          text: "\n\n",
                                        ),
                                        TextSpan(
                                          text:
                                              "Note: Responses on notes will count towards your usage.",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.info_outline),
                                      onPressed: () {},
                                    ),
                                  ),
                                ],
                              ),
                              FlexWithExtension.withSpacing(
                                direction: Axis.vertical,
                                spacing: 8,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // progress bar
                                  LinearProgressIndicator(
                                    borderRadius: BorderRadius.circular(16),
                                    minHeight: 10,
                                    value: usageFuture.data != null
                                        ? usageFuture.data?.usageRate ?? 0
                                        : null,
                                    color: lerpThreeColors(
                                      Theme.of(context)
                                          .extension<CustomColors>()
                                          ?.success,
                                      Theme.of(context)
                                          .extension<CustomColors>()
                                          ?.warning,
                                      Theme.of(context)
                                          .extension<CustomColors>()
                                          ?.danger,
                                      usageFuture.data?.usageRate,
                                    ),
                                  ),
                                  // usage info
                                  if (usageFuture.data != null) ...[
                                    if (usageFuture.data?.usageRate != null)
                                      Text(
                                        "${(usageFuture.data!.usageRate! * 100).toStringAsFixed(2)}% / 100.00%",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.6),
                                            ),
                                      ),

                                    // actual flat value
                                    Text(
                                      "Items: ${usageFuture.data?.usage} / ${usageFuture.data?.usageLimit ?? "Unlimited"}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.6),
                                          ),
                                    ),
                                  ],
                                ],
                              )
                            ],
                          ),

                          // media usage info
                          FlexWithExtension.withSpacing(
                            direction: Axis.vertical,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 8,
                            children: [
                              // media usage info title
                              Row(
                                children: [
                                  Text(
                                    "Media Usage",
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  ),
                                  // more info tooltip
                                  Tooltip(
                                    richMessage: const TextSpan(
                                      children: [
                                        TextSpan(
                                          text:
                                              "Media are images, videos, and other files that you add to notes.",
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.info_outline),
                                      onPressed: () {},
                                    ),
                                  ),
                                ],
                              ),

                              FlexWithExtension.withSpacing(
                                direction: Axis.vertical,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 8,
                                children: [
                                  // progress bar
                                  LinearProgressIndicator(
                                    borderRadius: BorderRadius.circular(16),
                                    minHeight: 10,
                                    value: usageFuture.data != null
                                        ? usageFuture.data?.mediaUsageRate ?? 0
                                        : null,
                                    color: lerpThreeColors(
                                      Theme.of(context)
                                          .extension<CustomColors>()
                                          ?.success,
                                      Theme.of(context)
                                          .extension<CustomColors>()
                                          ?.warning,
                                      Theme.of(context)
                                          .extension<CustomColors>()
                                          ?.danger,
                                      usageFuture.data?.mediaUsageRate,
                                    ),
                                  ),
                                  // usage info
                                  if (usageFuture.data != null) ...[
                                    if (usageFuture.data?.mediaUsageRate !=
                                        null)
                                      Text(
                                        "${(usageFuture.data!.mediaUsageRate! * 100).toStringAsFixed(2)}% / 100.00%",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.6),
                                            ),
                                      ),

                                    // actual flat value
                                    Text(
                                      "Media: ${filesize(usageFuture.data?.mediaUsage)} / ${usageFuture.data?.mediaUsageLimit != null ? filesize(usageFuture.data?.mediaUsageLimit) : "Unlimited"}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.6),
                                          ),
                                    ),
                                  ],
                                ],
                              )
                            ],
                          ),

                          // promo code button
                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.center,
                          //   children: [
                          //     // generate promo code button (for user "tackledinnovation@gmail.com" only)
                          //     if (Provider.of<AuthenticationService>(context)
                          //             .user
                          //             ?.email ==
                          //         "tackledinnovation@gmail.com")
                          //       ElevatedButton.icon(
                          //         onPressed: () async {
                          //           await showGeneratePromoCodeDialog(
                          //             context: context,
                          //           );
                          //         },
                          //         icon: const Icon(Symbols.manufacturing),
                          //         label: const Text("Generate Promo Code"),
                          //       ),

                          //     ElevatedButton.icon(
                          //       onPressed: () async {
                          //         await showPromoCodeDialog(context: context);
                          //         lastFetchTime.value = DateTime.now();
                          //       },
                          //       icon: const Icon(Icons.card_giftcard),
                          //       label: const Text("Redeem Promo Code"),
                          //     ),
                          //   ],
                          // )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // legal info
            const LegalInfo(),
          ],
        ),
      ),
    );
  }
}

class ResetPasswordButton extends HookWidget {
  static const String lastRequestTimeKey = 'lastRequestTime';
  const ResetPasswordButton({super.key, this.email, this.disabled});

  final bool? disabled;
  final String? email;

  Future<void> _updateLastPressedTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        lastRequestTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<int> _getTimeRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPressedTimeMillis = prefs.getInt(lastRequestTimeKey);
    if (lastPressedTimeMillis == null) return 0;
    final lastPressedTime =
        DateTime.fromMillisecondsSinceEpoch(lastPressedTimeMillis);
    final secondsPassed = DateTime.now().difference(lastPressedTime).inSeconds;
    return max(0, 60 - secondsPassed);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthenticationService>(context);
    final loadingState = useState<bool>(false);
    final timeRemaining = useState<int>(0);

    final timer = useRef<Timer?>(null);

    final restartTimer = useCallback(() async {
      final remaining = await _getTimeRemaining();
      if (remaining <= 0) {
        timer.value?.cancel();
        timeRemaining.value = 0;
        return;
      }
      timer.value?.cancel();
      timer.value = Timer.periodic(const Duration(seconds: 1), (timer) async {
        final remaining = await _getTimeRemaining();
        if (remaining <= 0) {
          timer.cancel();
        }
        timeRemaining.value = remaining;
      });
    }, [timer]);

    useEffect(() {
      restartTimer();
      return () => timer.value?.cancel();
    }, []);

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: ElevatedButton.icon(
        onPressed: disabled != true &&
                timeRemaining.value == 0 &&
                !loadingState.value &&
                email != null
            ? () async {
                var showSnackBar = ScaffoldMessenger.of(context).showSnackBar;
                loadingState.value = true;

                // show reauthenticate dialog
                await showReauthenticateDialog(
                  context: context,
                  onSuccess: () async {
                    await _updateLastPressedTime();

                    try {
                      await authService.resetPassword(email!);
                      loadingState.value = false;
                      timeRemaining.value = 60;
                      restartTimer(); // Reset the countdown

                      showSnackBar(
                        const SnackBar(
                          content: Text(
                              "Password reset email sent. Please check your inbox."),
                        ),
                      );
                    } catch (e) {
                      loadingState.value = false;
                      showSnackBar(
                        const SnackBar(
                          content: Text("Failed to send password reset email."),
                        ),
                      );
                    }
                  },
                  onCancel: () {
                    loadingState.value = false;
                  },
                  onFailure: (String error) {
                    loadingState.value = false;
                    showSnackBar(
                      SnackBar(
                        content: Text(error),
                      ),
                    );
                  },
                );
              }
            : null,
        icon: loadingState.value
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.lock),
        label: loadingState.value
            ? const Text("Sending email...")
            : (timeRemaining.value > 0
                ? Text("Wait ${timeRemaining.value}s")
                : const Text("Reset Password")),
      ),
    );
  }
}

class DeleteAccountButton extends HookWidget {
  const DeleteAccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        await showDeleteUserDialog(context: context);
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: Theme.of(context).extension<CustomColors>()?.danger,
      ),
      icon: const Icon(Icons.delete),
      label: const Text("Delete Account"),
    );
  }
}
