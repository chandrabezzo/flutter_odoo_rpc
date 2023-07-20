/// Odoo exceptions thrown by Odoo client

/// Generic exception thrown on error coming from Odoo server.
class OdooException implements Exception {
  /// Exception message coming from Odoo server.
  String message;
  OdooException(this.message);

  @override
  String toString() => 'OdooException: $message';
}

/// Exception for session expired error.
class OdooSessionExpiredException extends OdooException {
  /// Exception message coming from Odoo server.
  String odooSessionExpiredessage;

  OdooSessionExpiredException(this.odooSessionExpiredessage)
      : super(odooSessionExpiredessage);

  @override
  String toString() => 'OdooSessionExpiredException: $message';
}
