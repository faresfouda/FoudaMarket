import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectionAwareWidget extends StatefulWidget {
  final Widget child;
  final void Function(bool isOffline)? onConnectionChanged;

  const ConnectionAwareWidget({
    Key? key,
    required this.child,
    this.onConnectionChanged,
  }) : super(key: key);

  @override
  State<ConnectionAwareWidget> createState() => _ConnectionAwareWidgetState();
}

class _ConnectionAwareWidgetState extends State<ConnectionAwareWidget> {
  late final StreamController<ConnectivityResult> _controller;
  late final Stream<ConnectivityResult> _connectivityStream;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _controller = StreamController<ConnectivityResult>();
    Connectivity().onConnectivityChanged.listen((event) {
      if (event is ConnectivityResult) {
        _controller.add(event as ConnectivityResult);
      } else if (event is List) {
        final valid = event.whereType<ConnectivityResult>().toList();
        if (valid.isEmpty) {
          _controller.add(ConnectivityResult.none);
        } else {
          final first = valid.firstWhere((e) => e != ConnectivityResult.none, orElse: () => ConnectivityResult.none);
          _controller.add(first);
        }
      } else {
        _controller.add(ConnectivityResult.none);
      }
    });
    _connectivityStream = _controller.stream.asBroadcastStream();

    Connectivity().checkConnectivity().then((result) {
      final offline = result == ConnectivityResult.none;
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
    return StreamBuilder<ConnectivityResult>(
      stream: _connectivityStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final isNowOffline = snapshot.data == ConnectivityResult.none;
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
