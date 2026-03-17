import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/pairing_tokens.dart';
import '../widgets/pairing_action_button.dart';

class PairingSuccessScreen extends StatelessWidget {
  const PairingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PairingTokens.bgBase,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final widthScale = constraints.maxWidth / 375;
          final heightScale = constraints.maxHeight / 812;
          final contentWidth = 327 * widthScale;
          return Stack(
            children: [
              Positioned(
                left: 69 * widthScale,
                top: 125 * heightScale,
                child: Transform.scale(
                  alignment: Alignment.topLeft,
                  scale: widthScale,
                  child: const SizedBox(
                    width: 240,
                    height: 240,
                    child: _SuccessIllustration(),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 417 * heightScale,
                child: Container(
                  height: 395 * heightScale,
                  decoration: const BoxDecoration(
                    color: PairingTokens.bgSurface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      24 * widthScale,
                      40 * heightScale,
                      24 * widthScale,
                      24 * heightScale,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Congrats,\ndevice is added!',
                          style: PairingTextStyles.title2,
                        ),
                        SizedBox(height: 16 * heightScale),
                        Text(
                          'Your device is ready to go, let’s set up \nwhere to use it.',
                          style: PairingTextStyles.caption,
                        ),
                        SizedBox(height: 32 * heightScale),
                        SizedBox(
                          width: contentWidth,
                          child: PairingActionButton(
                            text: 'Control Device',
                            onPressed: () => Navigator.of(
                              context,
                            ).pushNamed('/spaces/device-control'),
                          ),
                        ),
                        SizedBox(height: 12 * heightScale),
                        SizedBox(
                          width: contentWidth,
                          child: PairingActionButton(
                            text: 'Back to Home',
                            onPressed: () =>
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/home',
                                  (route) => false,
                                ),
                            variant: PairingActionButtonVariant.neutral,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SuccessIllustration extends StatelessWidget {
  const _SuccessIllustration();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/pairing/success-illustration.svg',
      width: 240,
      height: 240,
      fit: BoxFit.contain,
    );
  }
}
