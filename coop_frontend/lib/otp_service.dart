class OtpService {
  static const String mockOtp = '123456';
  static const int resendTimeoutSeconds = 120;

  Future<bool> verifyOtp(String enteredOtp) async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));
    return enteredOtp == mockOtp;
  }

  Future<String> generateOtp() async {
    // Simulate OTP generation and sending
    await Future.delayed(const Duration(milliseconds: 500));
    return mockOtp;
  }

  static String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
