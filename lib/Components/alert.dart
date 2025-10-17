import 'package:flutter/material.dart';

void showAlert(BuildContext context, title, [bool ? confirmation = false, Function ? action ]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        actions: [
          Visibility(
            visible: confirmation == false,
            child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          )),
          Visibility(
            visible: confirmation!,
            child: Row(children: [
              TextButton(
            onPressed: () {action!(); Navigator.of(context).pop();} ,
            child: Text('Sim'),
          ),
          SizedBox(width: 100),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Não'),)

            ]) ),
          
        ],
      ),
    );
  }