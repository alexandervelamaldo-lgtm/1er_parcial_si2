import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/profile_data.dart';
import '../services/api_service.dart';


class SessionProvider extends ChangeNotifier {
  SessionProvider(this._apiService);

  final ApiService _apiService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _token;
  ProfileData? _profile;
  bool _loading = false;

  String? get token => _token;
  ProfileData? get profile => _profile;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get loading => _loading;

  Future<void> restaurarSesion() async {
    _token = await _storage.read(key: 'token');
    if (isAuthenticated) {
      try {
        _profile = await _apiService.obtenerPerfilActual(_token!);
      } catch (_) {
        _profile = null;
      }
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      _token = await _apiService.login(email: email, password: password);
      await _storage.write(key: 'token', value: _token);
      _profile = await _apiService.obtenerPerfilActual(_token!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _profile = null;
    await _storage.delete(key: 'token');
    notifyListeners();
  }
}
