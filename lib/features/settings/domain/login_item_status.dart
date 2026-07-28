enum LoginItemStatus {
  disabled('disabled'),
  enabled('enabled'),
  requiresApproval('requiresApproval'),
  unsupported('unsupported');

  const LoginItemStatus(this.platformValue);

  final String platformValue;

  static LoginItemStatus fromPlatformValue(String value) {
    return values.firstWhere(
      (status) => status.platformValue == value,
      orElse: () {
        throw FormatException('Unknown login item status: $value');
      },
    );
  }
}

enum LoginItemFailureKind {
  load,
  update,
  requiresApproval,
  unsupported,
  invalidResponse,
}

class LoginItemFailure implements Exception {
  const LoginItemFailure({required this.kind, this.cause});

  final LoginItemFailureKind kind;
  final Object? cause;
}
