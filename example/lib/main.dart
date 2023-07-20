import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_odoo_rpc/flutter_odoo_rpc.dart';

void sessionChanged(OdooSession sessionId) async {
  debugPrint('We got new session ID: ${sessionId.id}');
  // write to persistent storage
}

void loginStateChanged(OdooLoginEvent event) async {
  if (event == OdooLoginEvent.loggedIn) {
    debugPrint('Logged in');
  }
  if (event == OdooLoginEvent.loggedOut) {
    debugPrint('Logged out');
  }
}

void inRequestChanged(bool event) async {
  if (event) debugPrint('Request is executing'); // draw progress indicator
  if (!event) debugPrint('Request is finished'); // hide progress indicator
}

void main() async {
  // Restore session ID from storage and pass it to client constructor.
  const baseUrl = 'https://demo.odoo.com';
  final client = OdooClient(baseUrl);
  // Subscribe to session changes to store most recent one
  var subscription = client.sessionStream.listen(sessionChanged);
  var loginSubscription = client.loginStream.listen(loginStateChanged);
  var inRequestSubscription = client.inRequestStream.listen(inRequestChanged);

  try {
    // Authenticate to server with db name and credentials
    final session = await client.authenticate('odoo', 'admin', 'admin');
    debugPrint(session.toString());
    debugPrint('Authenticated');

    // Compute image avatar field name depending on server version
    final imageField =
        session.serverVersionInt >= 13 ? 'image_128' : 'image_small';

    // Read our user's fields
    final uid = session.userId;
    var res = await client.callKw({
      'model': 'res.users',
      'method': 'search_read',
      'args': [],
      'kwargs': {
        'context': {'bin_size': true},
        'domain': [
          ['id', '=', uid]
        ],
        'fields': ['id', 'name', '__last_update', imageField],
      },
    });
    debugPrint('\nUser info: \n$res');
    // compute avatar url if we got reply
    if (res.length == 1) {
      var unique = res[0]['__last_update'] as String;
      unique = unique.replaceAll(RegExp(r'[^0-9]'), '');
      final userAvatar =
          '$baseUrl/web/image?model=res.user&field=$imageField&id=$uid&unique=$unique';
      debugPrint('User Avatar URL: $userAvatar');
    }

    // Create partner
    var partnerId = await client.callKw({
      'model': 'res.partner',
      'method': 'create',
      'args': [
        {
          'name': 'Stealthy Wood',
        },
      ],
      'kwargs': {},
    });
    // Update partner by id
    res = await client.callKw({
      'model': 'res.partner',
      'method': 'write',
      'args': [
        partnerId,
        {
          'is_company': true,
        },
      ],
      'kwargs': {},
    });

    // Get list of installed modules
    res = await client.callRPC('/web/session/modules', 'call', {});
    debugPrint('\nInstalled modules: \n$res');

    // Check if loggeed in
    debugPrint('\nChecking session while logged in');
    res = await client.checkSession();
    debugPrint('ok');

    // Log out
    debugPrint('\nDestroying session');
    await client.destroySession();
    debugPrint('ok');
  } on OdooException catch (e) {
    // Cleanup on odoo exception
    debugPrint(e.message);
    await subscription.cancel();
    await loginSubscription.cancel();
    await inRequestSubscription.cancel();
    client.close();
    exit(-1);
  }

  debugPrint('\nChecking session while logged out');
  try {
    var res = await client.checkSession();
    debugPrint(res);
  } on OdooSessionExpiredException {
    debugPrint('Odoo Exception:Session expired');
  }
  await client.inRequestStream.isEmpty;
  await subscription.cancel();
  await loginSubscription.cancel();
  await inRequestSubscription.cancel();
  client.close();
}
