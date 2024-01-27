class ApiResponse<T> {
  String? error;
  T? result;
  int? code;
  ApiResponse({this.error, this.result, this.code});
}
