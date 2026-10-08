import 'package:flutter/material.dart';

import 'api_exceptions.dart';

void showApiError(BuildContext context, Object error) {
  final message = switch (error) {
    ForbiddenException e => '403: ${e.message}',
    ApiException e => e.message,
    _ => error.toString(),
  };
  final isForbidden = error is ForbiddenException;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isForbidden
          ? Theme.of(context).colorScheme.error
          : null,
    ),
  );
}

Future<void> runGuarded(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } on ApiException catch (e) {
    if (context.mounted) showApiError(context, e);
  } catch (e) {
    if (context.mounted) showApiError(context, e);
  }
}
