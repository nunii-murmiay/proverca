import 'package:flutter/material.dart';

import 'list_load_body.dart';

typedef LibraryLoader = Future<void> Function();

/// Подгружает редко открываемый раздел после старта приложения.
class DeferredPage extends StatefulWidget {
  final LibraryLoader loadLibrary;
  final WidgetBuilder builder;

  const DeferredPage({
    super.key,
    required this.loadLibrary,
    required this.builder,
  });

  @override
  State<DeferredPage> createState() => _DeferredPageState();
}

class _DeferredPageState extends State<DeferredPage> {
  late Future<void> _ready;

  @override
  void initState() {
    super.initState();
    _ready = widget.loadLibrary();
  }

  void _retry() {
    setState(() {
      _ready = widget.loadLibrary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Открываем раздел…'),
                ],
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: ConnectionProblem(
              message: 'Не удалось загрузить раздел. Проверьте соединение.',
              onRetry: _retry,
            ),
          );
        }
        return widget.builder(context);
      },
    );
  }
}
