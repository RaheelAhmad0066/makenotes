import 'package:flutter/material.dart';
import 'package:makernote/models/user.model.dart';

class UserListTile extends StatelessWidget {
  const UserListTile({
    super.key,
    required this.user,
    this.onTap,
    this.contentPadding,
  });
  final UserModel user;
  final void Function()? onTap;

  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: contentPadding ?? const EdgeInsets.all(0),
      subtitleTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
      leading: user.photoUrl != null
          ? CircleAvatar(
              backgroundImage: NetworkImage(user.photoUrl!),
            )
          : const CircleAvatar(
              child: Icon(Icons.person),
            ),
      title: Text(
        user.name ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        user.email,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }
}
