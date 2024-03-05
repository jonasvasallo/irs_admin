import 'package:flutter/material.dart';
import 'package:irs_admin/core/constants.dart';

class InputButton extends StatelessWidget {
  final String label;
  final Function function;
  final bool large;
  final Color? color;
  const InputButton(
      {Key? key,
      required this.label,
      required this.function,
      required this.large, this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: ButtonStyle(
        backgroundColor: MaterialStatePropertyAll((color != null) ? color : accentColor,),
        padding: MaterialStatePropertyAll(
          EdgeInsets.all((large) ? 16 : 8),
        ),
        minimumSize: MaterialStatePropertyAll(
          Size.fromHeight(43),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(8),
            ),
          ),
        ),
      ),
      onPressed: () => function(),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
