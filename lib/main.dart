import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Homesense',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Welcome Miller'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();

    var initializationSettingsAndroid =
        new AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
    intrude();
    firebaseCloudMessagingListeners();
  }

  Future onSelectNotification(String payload) async {
    showDialog(
      context: context,
      builder: (_) {
        return new AlertDialog(
          title: Text("Suspected Intrusion"),
          content: Text("Do you think this is an intruder?"),
          actions: <Widget>[
            FlatButton(
              child: Text('Yes'),
              onPressed: alertIntrusion,
            ),
            FlatButton(
              child: Text('No'),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
  }

  Future _showNotificationWithDefaultSound(String title, String body) async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High);
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'Default_Sound',
    );
  }

  void firebaseCloudMessagingListeners() {
    _firebaseMessaging.getToken().then((token) {
      print(token);
    });

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print(message["data"]["homesense"]);
        _showNotificationWithDefaultSound(
            message["notification"]["title"], message["notification"]["body"]);
      },
      onResume: (Map<String, dynamic> message) async {
        print('on resume $message');
      },
      onLaunch: (Map<String, dynamic> message) async {
        print('on launch $message');
      },
    );
  }

  void intrude() async {
    print('Intruding');
    await http.post('https://homesenseapi.herokuapp.com/api/intrusions',
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        body: json.encode({
          "intrusion": {"intrusion": false, "homesense_id": 1}
        }));
    print('Finished intruding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Text('YOUR HOMESENSE DEVICE HAS BEEN ENABLED'),
      ),
    );
  }

  void alertIntrusion() {
    intrusion(2);
    Navigator.pop(context);
  }

  Future<Null> intrusion(int homesense) async {
    print('Reporting intrusion');
    Map data = {
      "intrusion": {"intrusion": "true"}
    };
    final response = await http.put(
        'https://homesenseapi.herokuapp.com/api/intrusions/$homesense',
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        body: json.encode(data));
    if (response.statusCode == 200) {
      showDialog(
        context: context,
        builder: (_) {
          return new AlertDialog(
            title: Text("Reported"),
            content: Text(
                "This intrusion has been reported! You will receive a phone call from our staff shortly!"),
          );
        },
      );
    } else {
      print(response.body);
    }
  }
}
