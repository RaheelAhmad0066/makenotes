import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/services/item/accessibility.service.dart';
import 'package:makernote/utils/access_right.dart';
import 'package:provider/provider.dart';

class ItemSharing extends HookWidget {
  const ItemSharing({
    super.key,
    required this.itemId,
  });

  final String itemId;

  @override
  Widget build(BuildContext context) {
    AccessibilityService accessibilityService =
        Provider.of<AccessibilityService>(context, listen: false);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        //  show copiable token
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: FutureBuilder(
            future:
                accessibilityService.createToken(itemId, [AccessRight.read]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              // error handling
              if (snapshot.hasError) {
                return Text(
                  'Error getting token: ${snapshot.error}',
                  style: Theme.of(context).textTheme.bodyLarge,
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
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null ||
                          loadingProgress.cumulativeBytesLoaded ==
                              loadingProgress.expectedTotalBytes) {
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text('Copied token to clipboard'),
                        ),
                      );
                      Clipboard.setData(
                        ClipboardData(text: snapshot.data!.token),
                      );
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Row(
                        children: [
                          Text(
                            snapshot.data!.token,
                            style: Theme.of(context).textTheme.headlineLarge,
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
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
