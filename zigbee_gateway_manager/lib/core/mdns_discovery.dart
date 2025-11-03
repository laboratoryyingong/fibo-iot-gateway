import 'dart:async';
import 'package:multicast_dns/multicast_dns.dart';

class GatewayDiscoveryResult {
  final String host;
  final int port;
  final String service; // _smgw._tcp. / _mqtt._tcp. / _http._tcp.
  GatewayDiscoveryResult(this.host, this.port, this.service);
}

class MdnsDiscovery {
  Future<List<GatewayDiscoveryResult>> discover({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final client = MDnsClient();
    final out = <GatewayDiscoveryResult>[];
    await client.start();
    try {
      final services = ['_smgw._tcp.', '_mqtt._tcp.', '_http._tcp.'];
      for (final s in services) {
        await for (final ptr
            in client
                .lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(s))
                .timeout(timeout)) {
          await for (final srv
              in client
                  .lookup<SrvResourceRecord>(
                    ResourceRecordQuery.service(ptr.domainName),
                  )
                  .timeout(timeout)) {
            await for (final ip
                in client
                    .lookup<IPAddressResourceRecord>(
                      ResourceRecordQuery.addressIPv4(srv.target),
                    )
                    .timeout(timeout)) {
              out.add(GatewayDiscoveryResult(ip.address.address, srv.port, s));
            }
          }
        }
      }
    } catch (_) {
    } finally {
      client.stop();
    }
    return out;
  }
}
