import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';

void main(List<String> args) {
  if (args.firstOrNull == 'multi_window') {
    runApp(const MaterialApp(home: Scaffold(body: Center(child: Text('Sub Window Works!')))));
  } else {
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final window = await WindowController.create(const WindowConfiguration(arguments: 'test', hiddenAtLaunch: false));
              window.show();
            },
            child: const Text('Open Window'),
          ),
        ),
      ),
    ));
  }
}
