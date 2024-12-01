import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/models/user_list.wrapper.dart';
import 'package:makernote/services/item/accessibility.service.dart';
import 'package:makernote/utils/access_right.dart';
import 'package:provider/provider.dart';

class ItemSharingDialog extends HookWidget {
  ItemSharingDialog({
    super.key,
    this.title = 'Share item',
    required this.itemId,
  });
  final String title;
  final String itemId;

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    AccessibilityService accessibilityService =
        Provider.of<AccessibilityService>(context, listen: false);
    return ScaffoldMessenger(
      child: Builder(builder: (context) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: AlertDialog(
            title: Text(title),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 450,
              ),
              child: AnimatedContainer(
                width: MediaQuery.of(context).size.width * 0.6,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Scaffold(
                  body: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //  show copiable token
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                            child: FutureBuilder(
                              future: accessibilityService
                                  .createToken(itemId, [AccessRight.read]),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                }
                                // error handling
                                if (snapshot.hasError) {
                                  debugPrint(snapshot.error.toString());
                                  return Text(
                                    'Error getting token: ${snapshot.error}',
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  );
                                }

                                if (snapshot.data == null) {
                                  return const Text('No token found');
                                }

                                return Wrap(
                                  spacing: 8.0,
                                  direction: Axis.vertical,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    // QR code of token
                                    Image.network(
                                      'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=${snapshot.data!.token}&margin=10',
                                      width: 150,
                                      height: 150,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null ||
                                            loadingProgress
                                                    .cumulativeBytesLoaded ==
                                                loadingProgress
                                                    .expectedTotalBytes) {
                                          return child;
                                        }
                                        return Container(
                                          color: Colors.grey[300],
                                          height: 150,
                                          width: 150,
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      },
                                    ),

                                    // token text to copy
                                    GestureDetector(
                                      onTap: () {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              content: Text(
                                                  'Copied token to clipboard'),
                                            ),
                                          );
                                        }

                                        Clipboard.setData(
                                          ClipboardData(
                                              text: snapshot.data!.token),
                                        );
                                      },
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: Row(
                                          children: [
                                            Text(
                                              snapshot.data!.token,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineLarge,
                                            ),
                                            const SizedBox(width: 8.0),
                                            const Icon(Icons.copy),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // token expiry
                                    Text(
                                      // show expriy difference in days or hours if less than a day
                                      snapshot.data!.expiresAt
                                                  .toDate()
                                                  .difference(DateTime.now())
                                                  .inDays <
                                              1
                                          ? 'Expires in ${snapshot.data!.expiresAt.toDate().difference(DateTime.now()).inHours} hours'
                                          : 'Expires in ${snapshot.data!.expiresAt.toDate().difference(DateTime.now()).inDays} days',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      // list of sharing to users
                      Expanded(
                        child: SharingUsersList(
                          itemId: itemId,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              // un-share button
              // TextButton(
              //   style: TextButton.styleFrom(
              //     foregroundColor: Theme.of(context).colorScheme.error,
              //   ),
              //   onPressed: () async {
              //     Navigator.pop(context);
              //     await accessibilityService.removeAccessRight(itemId: itemId);
              //   },
              //   child: const Text('Unshare'),
              // ),

              // close button
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).hintColor,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class SharingUsersList extends HookWidget {
  const SharingUsersList({
    super.key,
    required this.itemId,
  });

  final String itemId;

  @override
  Widget build(BuildContext context) {
    final accessibilityService = Provider.of<AccessibilityService>(context);
    return SizedBox(
      width: 450,
      height: 800,
      child: Card(
        child: Column(
          children: [
            // title
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Sharing to users',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),

            const Divider(),

            Expanded(
              child: FutureBuilder(
                future: accessibilityService.getSharingUsers(itemId: itemId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // error handling
                  if (snapshot.hasError) {
                    debugPrint(snapshot.error.toString());
                    return Text(
                      'Error getting sharing users: ${snapshot.error}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    );
                  }

                  if (snapshot.data == null || snapshot.data!.isEmpty) {
                    return const Expanded(
                      child: Center(
                        child: Text(
                          'You could share the code to others',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  return ChangeNotifierProvider(
                    create: (_) => UserListWrapper(users: snapshot.data!),
                    builder: (context, _) {
                      final userList = Provider.of<UserListWrapper>(context);
                      return ListView.builder(
                        cacheExtent: 0.0,
                        shrinkWrap: true,
                        scrollDirection: Axis.vertical,
                        itemCount: userList.users.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: CircleAvatar(
                                backgroundImage:
                                    userList.users[index].photoUrl != null
                                        ? NetworkImage(
                                            userList.users[index].photoUrl!,
                                          )
                                        : null,
                                child: userList.users[index].photoUrl != null
                                    ? null
                                    : const Icon(Icons.person)),
                            title: Text(userList.users[index].name ?? ''),
                            subtitle: Text(
                              userList.users[index].email,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                await accessibilityService.removeAccessRight(
                                  itemId: itemId,
                                  userId: userList.users[index].uid,
                                );

                                // refresh list
                                userList.deleteUser(userList.users[index]);
                              },
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
