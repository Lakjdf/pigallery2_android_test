class LoginCredentials {
  String username;
  String password;
  bool rememberMe = false;

  LoginCredentials(this.username, this.password);

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
        'rememberMe': rememberMe,
      };
}
