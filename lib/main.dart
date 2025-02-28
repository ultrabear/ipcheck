import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IpCheck',
      theme: ThemeData(
        brightness: Brightness.light,
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),

      themeMode: ThemeMode.system,
      home: const MyHomePage(title: 'IpCheck'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum IpRequestState { yes, no, pending }

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.primary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            IPCheckWidget(version: IPVersion.v6),
            IPCheckWidget(version: IPVersion.v4),
          ],
        ),
      ),
    );
  }
}

enum IPVersion {
  v4,
  v6;

  String repr() {
    switch (this) {
      case IPVersion.v4:
        return 'IPv4';
      case IPVersion.v6:
        return 'IPv6';
    }
  }
}

class IPCheckWidget extends StatefulWidget {
  final IPVersion version;

  const IPCheckWidget({super.key, required this.version});

  @override
  State<IPCheckWidget> createState() => IPCheckWidgetState();
}

class IPCheckWidgetState extends State<IPCheckWidget> {
  IpRequestState ip = IpRequestState.pending;
  String? ipString;

  @override
  void initState() {
    super.initState();

    final String request;

    switch (widget.version) {
      case IPVersion.v4:
        request = '4';
      case IPVersion.v6:
        request = '6';
    }

    final c = http.Client();

    c
        .get(Uri.https("$request.icanhazip.com"))
        .then((r) {
          setState(() {
            ipString = r.body.trim();
            ip = IpRequestState.yes;
          });
        })
        .catchError((_) {
          setState(() {
            ip = IpRequestState.no;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final String out;

    final ipver = widget.version.repr();

    switch (ip) {
      case IpRequestState.pending:
        out = "Probing for $ipver support...";
      case IpRequestState.no:
        out = "$ipver is not supported.";
      case IpRequestState.yes:
        out = "$ipver is supported";
    }

    final Color cardColor;

    switch (ip) {
      case IpRequestState.no:
        cardColor = Colors.red;
      case IpRequestState.yes:
        cardColor = Colors.green;
      case IpRequestState.pending:
        cardColor = Colors.yellow;
    }

    return Card(
      shape: Border(left: BorderSide(width: 10, color: cardColor)),
      child: InkWell(
        splashColor: Theme.of(context).splashColor,
        onTap: () async {
          if (ipString case String s) {
            await Clipboard.setData(ClipboardData(text: s));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Copied $ipver address to clipboard")),
              );
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SizedBox(
            width: 600,
            child: Column(
              children: <Widget>[
                Text(out, style: Theme.of(context).textTheme.headlineMedium),
                if (ipString case String s)
                  Text(s, style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
