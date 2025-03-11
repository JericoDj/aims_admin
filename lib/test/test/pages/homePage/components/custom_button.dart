import 'package:flutter/material.dart';

// ignore: must_be_immutable
class CustomButton extends StatelessWidget {
  String text;
  VoidCallback onTap;
  Color textColor;
  Color buttonColor;

  CustomButton({
    super.key,
    required this.text,
    required this.onTap,
    this.textColor = Colors.white,
    this.buttonColor = const Color.fromARGB(255, 30, 136, 229),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        margin: const EdgeInsets.all(5),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(1),
        decoration: const BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.all(
            Radius.circular(30),
          ),
        ),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: const BorderRadius.all(
              Radius.circular(30),
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16.5,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
