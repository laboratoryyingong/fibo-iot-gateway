import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:fibo_core/services/gateway_linking_service.dart';
import 'package:fibo_core/services/hub_provisioning/hub_provisioning.dart';
import 'package:fibo_core/services/user_role_resolver.dart';
import 'package:fibo_core/theme/pairing_tokens.dart';
import '../widgets/gateway_dark_header.dart';
import '../widgets/gateway_info_card.dart';
import '../widgets/pairing_action_button.dart';
import 'gateway_provisioning_flow.dart';

/// Final provisioning step: stores the claim token on the hub (`hub-claim`)
/// and links it to the signed-in account.
///
/// The cloud-side claim API is a separate work stream (protocol doc §10) —
/// until it exists, the app issues a locally generated one-time token (the
/// hub treats it as opaque) and records the binding through the existing
/// Parse flow, keyed by the hub serial (= AWS IoT thing name).
class GatewayBindingScreen extends StatefulWidget {
  const GatewayBindingScreen({super.key});

  @override
  State<GatewayBindingScreen> createState() => _GatewayBindingScreenState();
}

class _GatewayBindingScreenState extends State<GatewayBindingScreen> {
  final _gatewayNameController = TextEditingController(text: 'My FIBO Hub');
  final _locationController = TextEditingController(text: 'Home / Living Room');

  HubProvisioningFlow? _flow;
  ParseUser? _currentUser;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_flow != null) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is HubProvisioningFlow) {
      _flow = args;
      _loadUser();
    }
  }

  @override
  void dispose() {
    _gatewayNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await ParseUser.currentUser() as ParseUser?;
    if (!mounted) return;
    setState(() => _currentUser = user);
  }

  GatewayProfile _profileFromHub(HubQrLabel label, HubInfo info) {
    final serial = info.serial.isNotEmpty ? info.serial : label.bleName;
    return GatewayProfile(
      id: 'hub-${serial.toLowerCase()}',
      name: _gatewayNameController.text.trim(),
      model: 'FIBO Hub',
      serialNumber: serial,
      firmwareVersion: info.firmwareVersion,
      connectionState: GatewayConnectionState.online,
      location: _locationController.text.trim(),
      lastSeenLabel: 'Just now',
    );
  }

  Future<void> _claimAndBind() async {
    final flow = _flow;
    final session = flow?.session;
    final user = _currentUser;
    if (flow == null || session == null || _saving) return;
    if (user == null) {
      _showError('You need to be signed in to claim a hub.');
      return;
    }

    setState(() => _saving = true);
    try {
      // Re-check the uplink right before claiming — a claimed hub that cannot
      // reach the cloud helps nobody (§6 of the app guide).
      final info = await session.readInfo();
      flow.info = info;
      if (!info.isOnline) {
        _showError('The hub lost its network link — go back and fix it '
            'before claiming.');
        return;
      }

      // TODO(cloud): replace with a backend-issued one-time claim token and
      // poll the binding-status API once that work stream lands.
      final token = 'fibo-app-${const Uuid().v4()}';
      await session.claim(token);

      final hadGatewayBefore = await GatewayLinkingService.hasLinkedGateway(
        user,
      );
      final profile = _profileFromHub(flow.label, info);
      final success = await GatewayLinkingService.bindGateway(
        user: user,
        gateway: profile,
        gatewayName: _gatewayNameController.text,
        location: _locationController.text,
      );
      if (!success) {
        _showError('The hub was claimed, but saving to your account failed. '
            'Please try again.');
        return;
      }

      flow.completed = true;
      await flow.close();
      if (!mounted) return;
      final nextRoute = hadGatewayBefore
          ? GatewayLinkingService.listRoute
          : resolveHomeRoute(user);
      Navigator.of(context).pushNamedAndRemoveUntil(nextRoute, (route) => false);
    } on HubEndpointException catch (e) {
      _showError('The hub rejected the claim (${e.status}).');
    } catch (e) {
      _showError('Claim failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final flow = _flow;
    final info = flow?.info;
    final accountLabel = _resolveAccountLabel();

    return Scaffold(
      backgroundColor: PairingTokens.bgBase,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            GatewayDarkHeader(
              title: 'Claim Hub',
              onLeadingTap: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: SizedBox(
                        width: 295,
                        child: Text(
                          'Link this hub to your account and assign basic '
                          'info',
                          textAlign: TextAlign.center,
                          style: PairingTextStyles.caption.copyWith(
                            color: PairingTokens.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (flow != null && info != null)
                      GatewayInfoCard(gateway: _profileFromHub(flow.label, info)),
                    if (info != null && info.claimed) ...[
                      const SizedBox(height: 10),
                      Text(
                        'This hub was claimed before — continuing will '
                        're-claim it for this account.',
                        style: PairingTextStyles.small.copyWith(
                          color: const Color(0xFFFFB74D),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Text(
                      'Linked Account',
                      style: PairingTextStyles.small.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GatewayInfoCard(
                      gateway: GatewayProfile(
                        id: 'account',
                        name: accountLabel.$1,
                        model: 'Linked Account',
                        serialNumber: accountLabel.$2,
                        firmwareVersion: '',
                        connectionState: GatewayConnectionState.online,
                      ),
                      trailing: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: PairingTokens.accentEnd,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 16,
                          color: PairingTokens.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    _InputSection(
                      label: 'Hub Name',
                      controller: _gatewayNameController,
                      hint: 'My FIBO Hub',
                    ),
                    const SizedBox(height: 18),
                    _InputSection(
                      label: 'Location (Optional)',
                      controller: _locationController,
                      hint: 'Home / Living Room',
                      trailingIcon: Icons.place_outlined,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: PairingActionButton(
                text: _saving ? 'Claiming...' : 'Claim & Bind',
                onPressed: _claimAndBind,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, String) _resolveAccountLabel() {
    final username = (_currentUser?.username ?? '').trim();
    final email = (_currentUser?.emailAddress ?? '').trim();
    if (username.isEmpty && email.isEmpty) return ('Current User', 'No email');
    return (
      username.isEmpty ? email : username,
      email.isEmpty ? 'Signed in' : email,
    );
  }
}

class _InputSection extends StatelessWidget {
  const _InputSection({
    required this.label,
    required this.controller,
    required this.hint,
    this.trailingIcon,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: PairingTextStyles.title3),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          style: PairingTextStyles.body,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.transparent,
            hintText: hint,
            hintStyle: PairingTextStyles.body.copyWith(
              color: PairingTokens.textMuted,
            ),
            suffixIcon: trailingIcon == null
                ? null
                : Icon(trailingIcon, color: PairingTokens.textMuted, size: 18),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 17,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: PairingTokens.bgElevated, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: PairingTokens.bgElevated, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: PairingTokens.accentPrimary,
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
