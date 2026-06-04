Future<bool> signIn(String email, String password) async {
  _status = AuthStatus.loading;
  _error = null;
  notifyListeners();

  try {
    final user = await _authService.signIn(email, password);
    if (user == null) {
      _error = 'فشل تسجيل الدخول';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
    // Now user is non-null
    if (user.role != 'patient') {
      _error = 'هذا التطبيق مخصص للمرضى فقط. دورك: ${user.role}';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
    _user = user;
    _status = AuthStatus.authenticated;
    notifyListeners();
    return true;
  } catch (e) {
    _error = e.toString().replaceAll('Exception: ', '');
    _status = AuthStatus.unauthenticated;
    notifyListeners();
    return false;
  }
}
