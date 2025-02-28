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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
          primary: Colors.blue,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
          primary: Colors.blue,
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

class _MyHomePageState extends State<MyHomePage> {
  int _resets = 0;

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
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(widget.title),

        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: "Refresh IPv4/6 checks",
            onPressed: () => setState(() => ++_resets),
          ),
        ],
      ),
      body: Center(
        child: KeyedSubtree(
          key: ValueKey(_resets),
          child: RefreshIndicator(
            child: ListView(
              children: <Widget>[
                IPCheckWidget(version: IPVersion.v6),
                IPCheckWidget(version: IPVersion.v4),
              ],
            ),

            onRefresh: () async {
              setState(() => ++_resets);
            },
          ),
        ),
      ),
    );
  }
}

enum IPVersion {
  v4,
  v6;

  String repr() => switch (this) {
    IPVersion.v4 => 'IPv4',
    IPVersion.v6 => 'IPv6',
  };

  String icanhaz() => switch (this) {
    IPVersion.v4 => "4",
    IPVersion.v6 => "6",
  };
}

sealed class IPQuery {
  Icon repr();
}

class PendingIp implements IPQuery {
  @override
  Icon repr() => Icon(Icons.pending);
}

class NoIp implements IPQuery {
  @override
  Icon repr() => Icon(Icons.error);
}

class YesIp implements IPQuery {
  final String ip;

  const YesIp(this.ip);
  @override
  Icon repr() => Icon(Icons.copy);
}

class IPCheckWidget extends StatefulWidget {
  final IPVersion version;

  const IPCheckWidget({super.key, required this.version});

  @override
  State<IPCheckWidget> createState() => IPCheckWidgetState();
}

class IPCheckWidgetState extends State<IPCheckWidget> {
  IPQuery _ip = PendingIp();
  bool _show = false;

  @override
  void initState() {
    super.initState();

    final request = widget.version.icanhaz();

    final c = http.Client();

    c
        .get(Uri.https("$request.icanhazip.com"))
        .then((r) async {
          setState(() {
            _ip = YesIp(r.body.trim());
          });
        })
        .catchError((_) {
          setState(() {
            _ip = NoIp();
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final ipver = widget.version.repr();

    final (out, cardColor) = switch (_ip) {
      PendingIp() => ("Probing for $ipver support...", Colors.yellow),
      NoIp() => ("$ipver is not supported.", Colors.red),
      YesIp() => ("$ipver is supported", Colors.green),
    };

    return Card(
      shape: Border(left: BorderSide(width: 10, color: cardColor)),
      child: InkWell(
        splashColor: Theme.of(context).splashColor,
        onTap: () async {
          if (_ip case YesIp(ip: final s)) {
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
            width: 550,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(),
                Expanded(
                  flex: 5,
                  child: Column(
                    children: <Widget>[
                      Text(
                        out,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      if (_ip case YesIp(ip: final s))
                        _show
                            ? Text(
                              s,
                              style: Theme.of(context).textTheme.headlineSmall,
                            )
                            : TextButton(
                              child: Text(
                                "Reveal IP",
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              onPressed: () => setState(() => _show = true),
                            ),
                    ],
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _ip.repr(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
