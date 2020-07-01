import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:distance/components/location.dart';


class Home extends StatelessWidget {
	Home({Key key}) : super(key: key);

	@override
	Widget build(BuildContext context) {
		return new Scaffold(
        body: Container(
					decoration: BoxDecoration(
						image: DecorationImage(
							image: AssetImage("images/sky.png"),
							fit: BoxFit.cover,
						),
					),
				  child: HomePage(),
				),
		);
	}

}

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  HomePageState createState() => new HomePageState();
}

class HomePageState extends State<HomePage> {
	var geolocator = Geolocator();
	Position start_position;
	String start_position_text = '';
	StreamSubscription _getPositionSubscription;

  //ボタンを押した後の処理
  Future<void> _buttonPressed() async {
		if (start_position_text == '' && _selectedItem != 0) {
			var locationOptions = LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);
			Position start_position = await geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
			setState(() {
			  start_position_text = start_position.latitude.toString() + ', ' + start_position.longitude.toString();
			});
			_getPositionSubscription = geolocator.getPositionStream(locationOptions).listen(
			(Position position) {
				print(position == null ? 'Unknown' : position.latitude.toString() + ', ' + position.longitude.toString());
				judge_distance(start_position, position);
			});
		} else if (_selectedItem != 0) {
			_getPositionSubscription?.cancel();
			_getPositionSubscription = null;;
			start_position = null;
			setState(() {
			  start_position_text = '';
			});
			print(start_position_text);
		} else {
			showDialog<void>(
				context: context,
				barrierDismissible: false, // user must tap button!
				builder: (BuildContext context) {
					return AlertDialog(
						content: SingleChildScrollView(
							child: ListBody(
								children: <Widget>[
									Text('距離を設定してください。'),
								],
							),
						),
						actions: <Widget>[
							FlatButton(
								child: Text('OK'),
								onPressed: () {
									Navigator.of(context).pop();
								},
							),
						],
					);
				},
			);
		}
  }

	void judge_distance(Position start_position, Position last_position) async {
		double distance = await Geolocator().distanceBetween(start_position.latitude, start_position.longitude, last_position.latitude, last_position.longitude);
		print(distance);
		if (distance >= _selectedItem) {
	    _onNotification();
			_neverSatisfied();
			_getPositionSubscription?.cancel();
			_getPositionSubscription = null;;
			start_position = null;
			setState(() {
			  start_position_text = '';
			});
			print(start_position_text);
		}
	}

  Widget buildFloatingButton(String text, VoidCallback callback) {
    TextStyle roundTextStyle = const TextStyle(fontSize: 35.0, color: Colors.black,fontFamily: "Bebas Neue");
    Container myFabButton = Container(
      width: 300.0,
      height: 100.0,
      child: new RawMaterialButton(
				shape: OutlineInputBorder(
					borderRadius: BorderRadius.all(Radius.circular(20.0)),
				),
        elevation: 0.0,
        child: new Text(text, style: roundTextStyle),
        onPressed: callback,
      ),
    );
    return myFabButton;
  }

  @override
  Widget build(BuildContext context) {
    return new Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        new Expanded(
          flex: 2,
					child: Center(
						child: Column(
							mainAxisAlignment: MainAxisAlignment.center,
							crossAxisAlignment: CrossAxisAlignment.center,
							children: <Widget>[
                Text(start_position_text == "" ?"" : "計測中", style: TextStyle(fontSize: 50.0, fontFamily: "Bebas Neue")),
							],
						),
					),
        ),
        new Expanded(
          child: new Center(
            child: new Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                buildFloatingButton(start_position_text == "" ?"開始" : "中止", _buttonPressed),
              ],
            ),
          ),
        ),
        new Expanded(
          flex: 2,
					child: Center(
						child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
							crossAxisAlignment: CrossAxisAlignment.center,
							children: <Widget>[
								Text(_selectedItem == 0 ?"距離を設定してください" : _selectedItem.toString() + 'm', style: TextStyle(fontSize: 30.0, )),
								Text(_selectedItem == 0 ?"" : "以上、離れると通知されます。", style: TextStyle(fontSize: 20.0, )),
								distance_select_button(),
							],
						),
					),
        ),
      ],
    );
  }

	Widget distance_select_button() {
		if (start_position_text == "") {
			Container myFabButton = Container(
				width: 300.0,
				height: 80.0,
				child: new RawMaterialButton(
					shape: OutlineInputBorder(
						borderRadius: BorderRadius.all(Radius.circular(10.0)),
					),
					elevation: 0.0,
				  child: Text('距離設定', style: TextStyle(fontSize: 30.0,)),
					onPressed: () {
						_showModalPicker(context);
					},
				),
			);
			return myFabButton;
		} else {
			return Text("");
		}
  }

	//通知処理
	FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  NotificationDetails platformChannelSpecifics;

	@override
  void initState() {
    super.initState();

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocationLocation);
    var initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }
	Future onSelectNotification(String payload) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Text(payload),
        maintainState : false,),
    );
  }
	Future onDidReceiveLocationLocation(int id, String title, String body, String payload) async {
	  await showDialog(
			context: context,
			builder: (BuildContext context) {
				return AlertDialog(
					title: Text(title),
					content:  Text(body),
					actions: <Widget>[
						FlatButton(
							child: Text(payload),
							onPressed: () {
								Navigator.of(context).pop();
							},
						),
					],
				);
			}
	  );
	}
	Future _onNotification() async {
		var androidPlatformChannelSpecifics = AndroidNotificationDetails(
				'your channel id', 'your channel name', 'your channel description',
				importance: Importance.Max, priority: Priority.High, ticker: 'ticker');
		var iOSPlatformChannelSpecifics = IOSNotificationDetails();
		var platformChannelSpecifics = NotificationDetails(
				androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
		await flutterLocalNotificationsPlugin.show(
				0, 'DISTANCE', '目標距離に到着いたしました。', platformChannelSpecifics,
				);
  }

	//到着後ダイアログ
	Future<void> _neverSatisfied() async {
		return showDialog<void>(
			context: context,
			barrierDismissible: false, // user must tap button!
			builder: (BuildContext context) {
				return AlertDialog(
					title: Text('到着通知'),
					content: SingleChildScrollView(
						child: ListBody(
							children: <Widget>[
								Text('目標距離に到着致しました。'),
							],
						),
					),
					actions: <Widget>[
						FlatButton(
							child: Text('OK'),
							onPressed: () {
								Navigator.of(context).pop();
							},
						),
					],
				);
			},
		);
	}

  //pickerの処理
  void _showModalPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height / 3,
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: CupertinoPicker(
              itemExtent: 40,
              children: _items.map(_pickerItem).toList(),
              onSelectedItemChanged: _onSelectedItemChanged,
            ),
          ),
        );
      },
    );
  }
  int _selectedItem = 0;

  final List<int> _items = [
		0,
    100,
    200,
    300,
    400,
    500,
    1000,
    2000,
    3000,
    4000,
    5000,
    6000,
    7000,
    8000,
    9000,
    10000,
  ];

  Widget _pickerItem(int str) {
    return Text(
      str.toString(),
      style: const TextStyle(fontSize: 32),
    );
  }

  void _onSelectedItemChanged(int index) {
    setState(() {
      _selectedItem = _items[index];
    });
  }

}
