import 'package:flutter/material.dart';

class AppBarWidget extends StatelessWidget  {
  const AppBarWidget({
    Key? key,
    required this.icon,
    required this.title,
    required this.onPressed,
    this.actions,
    this.subtitle,
  }) : super(key: key);

  final IconData icon;
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Padding(
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Row(children: [
          ElevatedButton(
            onPressed: onPressed, 
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 60), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            child: Row(children: [
              Icon(icon), 
              const SizedBox(width: 13),
              Text(
                title!, 
                maxLines: 1,
                overflow: TextOverflow.fade,
                style: Theme.of(context).textTheme.headline6!.copyWith(letterSpacing: 1, color: Colors.white)
              )
            ]),
          ),
          const Spacer(),
          ...?actions
        ] ),
      ),
    ) );
  }
}