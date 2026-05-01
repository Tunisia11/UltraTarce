import 'package:flutter/material.dart';

class SplashWordmark extends StatelessWidget {
  const SplashWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Trace Ultra',
      image: true,
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Trace',
                style: TextStyle(
                  color: Color(0xFF0B2F21),
                  fontSize: 96,
                  fontWeight: FontWeight.w900,
                  height: .9,
                  letterSpacing: 0,
                ),
              ),
              Text(
                'Ultra',
                style: TextStyle(
                  color: Color(0xFF6DAE35),
                  fontSize: 96,
                  fontWeight: FontWeight.w900,
                  height: .9,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
