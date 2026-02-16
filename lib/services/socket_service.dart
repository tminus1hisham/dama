import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;
  static final SocketService _instance = SocketService._internal();
  bool _isConnected = false;
  Completer<void>? _connectionCompleter;
  Function(dynamic)? _currentMessageListener;

  factory SocketService() => _instance;

  SocketService._internal();

  bool get isConnected => _isConnected;

  Future<void> connect(String token) async {
    if (_isConnected) return;

    // If already connecting, wait for that connection
    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      return _connectionCompleter!.future;
    }

    _connectionCompleter = Completer<void>();

    socket = IO.io(
      'http://167.71.68.0:5000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setQuery({'token': token})
          .build(),
    );

    socket.onConnect((_) {
      _isConnected = true;
      if (!_connectionCompleter!.isCompleted) {
        _connectionCompleter!.complete();
      }
    });

    socket.onDisconnect((_) {
      _isConnected = false;
    });

    socket.onConnectError((error) {
      if (!_connectionCompleter!.isCompleted) {
        _connectionCompleter!.completeError(error);
      }
    });
    socket.onError((error) => null);

    socket.connect();

    // Wait for connection with timeout
    try {
      await _connectionCompleter!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Socket connection timed out');
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  void joinConversation(String conversationId) {
    if (!_isConnected) {
      return;
    }
    socket.emit('joinConversation', conversationId);
  }

  void leaveConversation(String conversationId) {
    if (!_isConnected) return;
    socket.emit('leaveConversation', conversationId);
  }

  void sendMessage(Map<String, dynamic> message) {
    if (!_isConnected) {
      debugPrint('Cannot send message: socket not connected');
      return;
    }
    socket.emit('sendMessage', message);
  }

  void listenForMessages(Function(dynamic) callback) {
    // Remove previous listener to avoid duplicates
    if (_currentMessageListener != null) {
      socket.off('receiveMessage', _currentMessageListener);
    }
    _currentMessageListener = callback;
    socket.on('receiveMessage', callback);
  }

  void removeMessageListener() {
    if (_currentMessageListener != null) {
      socket.off('receiveMessage', _currentMessageListener);
      _currentMessageListener = null;
    }
  }

  void dispose() {
    removeMessageListener();
    if (_isConnected) {
      socket.disconnect();
    }
    socket.destroy();
    _isConnected = false;
    _connectionCompleter = null;
  }
}
