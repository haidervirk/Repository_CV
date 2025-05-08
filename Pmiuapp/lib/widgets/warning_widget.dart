import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

provideWarningWidget ({required String message}) {
  return SnackBar(
    content: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.warning, size: 20, color: Colors.white,),
        const Gap(8.0),
        Text(
          message,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ],
    ),
    backgroundColor: Colors.red,
  );
}
