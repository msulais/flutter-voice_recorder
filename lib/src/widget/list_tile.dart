import 'package:flutter/material.dart';

class SelectListTileWidget extends StatelessWidget {
  const SelectListTileWidget({
    Key? key,
    required this.icon,
    required this.labelText,
    required this.value,
    required this.onTap,
  }) : super(key: key);

  final IconData icon;
  final String labelText;
  final String value;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(labelText),
      leading: Icon(icon),
      trailing: Material(
        color: Colors.red[100],
        borderRadius: BorderRadius.circular(100),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10),
          child: Text(value, style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.w500))
        ),
      ),
      onTap: onTap,
    );
  }
}