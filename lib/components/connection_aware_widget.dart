import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectionAwareWidget extends StatefulWidget {
  final Widget child;
  final void Function(bool isOffline)? onConnectionChanged;

  const ConnectionAwareWidget({
    super.key,
    required this.child,
    this.onConnectionChanged,
  });

  @override
  State<ConnectionAwareWidget> createState() => _ConnectionAwareWidgetState();
}

class _ConnectionAwareWidgetState extends State<ConnectionAwareWidget> {
  late final StreamController<List<ConnectivityResult>> _controller;
  late final Stream<List<ConnectivityResult>> _connectivityStream;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _controller = StreamController<List<ConnectivityResult>>();
    Connectivity().onConnectivityChanged.listen((event) {
      _controller.add(event);
    });
    _connectivityStream = _controller.stream.asBroadcastStream();

    Connectivity().checkConnectivity().then((results) {
      final offline =
          results.isEmpty ||
          results.every((result) => result == ConnectivityResult.none);
      setState(() {
        _isOffline = offline;
      });
      widget.onConnectionChanged?.call(offline);
    });
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: _connectivityStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final results = snapshot.data!;
          final isNowOffline =
              results.isEmpty ||
              results.every((result) => result == ConnectivityResult.none);
          if (isNowOffline != _isOffline) {
            _isOffline = isNowOffline;
            widget.onConnectionChanged?.call(_isOffline);
          }
        }

        return Stack(
          children: [
            widget.child,
            if (_isOffline)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: MaterialBanner(
                  content: const Text(
                    'لا يوجد اتصال بالإنترنت',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.red,
                  actions: const [SizedBox.shrink()],
                ),
              ),
          ],
        );
      },
    );
  }
}
