import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'screens/home.dart';

class App extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => AppState();
}

class AppState extends State<App> {

  @override
  Widget build(BuildContext context) {
		return Scaffold(
			body:
		 	  Center(
				  child: Home()
				),
		);
  }
}

