import 'package:flutter/material.dart';


Future selectDialogWidget(BuildContext context, String title, List<Widget> children){
  return showDialog(context: context, builder: (context) => Dialog(
    clipBehavior: Clip.hardEdge,
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.headline5),
          const Spacer(),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.clear), splashRadius: 24),
        ] ),
        const Divider(height: 0),
        Flexible(child: Material(color: Colors.transparent, child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(children: children)
        )))
      ]),
    ),
  ));
}