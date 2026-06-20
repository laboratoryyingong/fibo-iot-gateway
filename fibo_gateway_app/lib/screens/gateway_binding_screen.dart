import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:fibo_core/services/gateway_linking_service.dart';
import 'package:fibo_core/services/user_role_resolver.dart';
import 'package:fibo_core/theme/pairing_tokens.dart';
import '../widgets/gateway_dark_header.dart';
import '../widgets/gateway_info_card.dart';
import '../widgets/pairing_action_button.dart';

class GatewayBindingScreenArgs {
  const GatewayBindingScreenArgs({required this.gateway});

  final GatewayProfile gateway;
}

class GatewayBindingScreen extends StatefulWidget {
  const GatewayBindingScreen({super.key});

  @override
  State<GatewayBindingScreen> createState() => _GatewayBindingScreenState();
}

class _GatewayBindingScreenState extends State<GatewayBindingScreen> {
  final _gatewayNameController = TextEditingController();
  final _locationController = TextEditingController(text: 'Home / Living Room');

  GatewayProfile? _gateway;
  ParseUser? _currentUser;
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args =
        ModalRoute.of(context)?.settings.arguments as GatewayBindingScreenArgs?;
    _gateway = args?.gateway ?? GatewayLinkingService.suggestedGateway();
    _gatewayNameController.text = _gateway!.name;
    _locationController.text = _gateway!.location ?? 'Home / Living Room';
    _loadUser();
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

  Future<void> _bindGateway() async {
    final gateway = _gateway;
    final user = _currentUser;
    if (gateway == null || user == null || _saving) return;

    setState(() => _saving = true);
    final hadGatewayBefore = await GatewayLinkingService.hasLinkedGateway(user);
    final success = await GatewayLinkingService.bindGateway(
      user: user,
      gateway: gateway,
      gatewayName: _gatewayNameController.text,
      location: _locationController.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to bind gateway right now.')),
      );
      return;
    }

    final nextRoute = hadGatewayBefore
        ? GatewayLinkingService.listRoute
        : resolveHomeRoute(user);
    Navigator.of(context).pushNamedAndRemoveUntil(nextRoute, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final gateway = _gateway ?? GatewayLinkingService.suggestedGateway();
    final accountLabel = _resolveAccountLabel();

    return Scaffold(
      backgroundColor: PairingTokens.bgBase,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            GatewayDarkHeader(
              title: 'Bind Gateway',
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
                          'Link gateway to your account and assign basic info',
                          textAlign: TextAlign.center,
                          style: PairingTextStyles.caption.copyWith(
                            color: PairingTokens.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    GatewayInfoCard(gateway: gateway),
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
                      label: 'Gateway Name',
                      controller: _gatewayNameController,
                      hint: 'My FIBO Gateway',
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
                text: _saving ? 'Binding...' : 'Bind & Continue',
                onPressed: _bindGateway,
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
