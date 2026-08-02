import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:fibo_core/services/gateway_linking_service.dart';
import 'package:fibo_core/theme/pairing_tokens.dart';
import '../widgets/gateway_dark_header.dart';
import '../widgets/gateway_info_card.dart';
import 'space_models.dart';

class GatewayListScreen extends StatefulWidget {
  const GatewayListScreen({super.key});

  @override
  State<GatewayListScreen> createState() => _GatewayListScreenState();
}

class _GatewayListScreenState extends State<GatewayListScreen> {
  ParseUser? _user;
  List<GatewayProfile> _gateways = const [];
  String? _selectedGatewayId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await ParseUser.currentUser() as ParseUser?;

    // Prefer the real gateways from the live home graph (fibo-hub-001); fall
    // back to the locally-stored list only when the graph isn't available.
    final graph = SpaceMockStore.instance.homeGraph;
    List<GatewayProfile> gateways;
    String? selectedId;
    if (graph != null && graph.gateways.isNotEmpty) {
      gateways = GatewayLinkingService.realGatewaysFromGraph(graph);
      selectedId = gateways.first.id;
    } else {
      gateways = await GatewayLinkingService.getLinkedGateways(user);
      selectedId = (await GatewayLinkingService.getSelectedGateway(user))?.id;
    }

    if (!mounted) return;
    setState(() {
      _user = user;
      _gateways = gateways;
      _selectedGatewayId = selectedId;
      _loading = false;
    });
  }

  Future<void> _selectAndOpenDetail(GatewayProfile gateway) async {
    final user = _user;
    if (user == null) return;
    await GatewayLinkingService.selectGateway(
      user: user,
      gatewayId: gateway.id,
    );
    if (!mounted) return;
    await Navigator.of(
      context,
    ).pushNamed(GatewayLinkingService.detailRoute, arguments: gateway.id);
    await _load();
  }

  Future<void> _addGateway() async {
    await Navigator.of(context).pushNamed('/gateway/qr-scan');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final activeGateway = _gateways.where(
      (gateway) => gateway.id == _selectedGatewayId,
    );
    final otherGateways = _gateways
        .where((gateway) => gateway.id != _selectedGatewayId)
        .toList(growable: false);

    return Scaffold(
      backgroundColor: PairingTokens.bgBase,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  GatewayDarkHeader(
                    title: 'My Gateways',
                    onLeadingTap: () => Navigator.of(context).maybePop(),
                    trailingIcon: Icons.add,
                    onTrailingTap: _addGateway,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (activeGateway.isNotEmpty)
                            GatewayInfoCard(
                              gateway: activeGateway.first,
                              highlighted: true,
                              showLocation: true,
                              onTap: () =>
                                  _selectAndOpenDetail(activeGateway.first),
                            )
                          else
                            _EmptyGatewayCard(onAdd: _addGateway),
                          const SizedBox(height: 30),
                          Text(
                            'OTHER GATEWAYS',
                            style: PairingTextStyles.small.copyWith(
                              color: PairingTokens.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (otherGateways.isEmpty)
                            Text(
                              'No additional gateways linked yet.',
                              style: PairingTextStyles.caption.copyWith(
                                color: PairingTokens.textMuted,
                              ),
                            )
                          else
                            ...otherGateways.map(
                              (gateway) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GatewayInfoCard(
                                  gateway: gateway,
                                  trailing: const Icon(
                                    Icons.chevron_right,
                                    color: PairingTokens.textMuted,
                                  ),
                                  onTap: () => _selectAndOpenDetail(gateway),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _EmptyGatewayCard extends StatelessWidget {
  const _EmptyGatewayCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onAdd,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [PairingTokens.bgElevated, PairingTokens.bgSurface],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.add_circle_outline,
              color: PairingTokens.accentPrimary,
              size: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No gateway linked yet. Tap to add one.',
                style: PairingTextStyles.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
