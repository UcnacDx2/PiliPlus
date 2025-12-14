import 'package:flutter/material.dart';

class TvTopControl extends StatelessWidget {
  const TvTopControl({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        FocusableActionDetector(
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {},
          ),
        ),
        const Text(
          'TV Top Control',
          style: TextStyle(color: Colors.white),
        ),
        FocusableActionDetector(
          child: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}
