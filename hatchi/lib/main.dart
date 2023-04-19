import 'dart:io';

import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';

import 'proto/connectors.pbgrpc.dart';

const String socket = "/tmp/test.socket";

void main() {
  initGRPCServer();
  runApp(const MyApp());
}

initGRPCServer() async {
  // fetch the root of the project
  // use env variable when testing
  String home = const String.fromEnvironment("HATCHI_HOME");
  if (home.isEmpty) {
    home = Directory(Platform.script.path).parent.path;
  }

  // check if socket is binded, close if true
  if (File(socket).existsSync()) {
    File(socket).delete();
  }

  // start the Go gRPC server, creates socket by default
  var server = await Process.start("./server", [],
      workingDirectory: "$home/backend/");
  stdout.addStream(server.stdout);
  stderr.addStream(server.stderr);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // output and input to gRPC
  String result = "";
  Query input = Query(query: "SELECT 1,2,3;");
  TextEditingController textController = TextEditingController();
  String home = Directory(Platform.script.path).parent.path;

  // start the gRPC client over UDS and without TLS
  DatabaseConnectClient client = DatabaseConnectClient(ClientChannel(
      InternetAddress(socket, type: InternetAddressType.unix),
      options:
          const ChannelOptions(credentials: ChannelCredentials.insecure())));
  

  // send to gRPC and set result
  void _callGrpcService() async {
    // server initially have nil database
    const String connector = "sqlite";
    ConnectionOptions options = await client.selectConnector(ConnectorName(name: connector));

    await client.connect(
      ConnectionOptions(
        connectorName:connector, 
        fields: 
        [ConnectionOptionField(name: options.fields[0].name, require: options.fields[0].require, value: ":memory")]));
    
    try {
      var response = await client.execute(input);
      var availableDatabases = await client.listConnectors(Empty());
      setState(() {
        result = "";
        result += availableDatabases.names.join(" ");
        result += response.result.map(
            (e) => e.row.join(" ")
        ).join('\n');
      });
    } on GrpcError catch (e) {
      setState(() {
        result = e.message.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Column(children: <Widget>[
          TextFormField(
            controller: textController,
            decoration: InputDecoration(
                filled: true,
                hintText: "Enter SQL Query",
                // fillColor: Colors.red,
                border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(20))),
          ),
          Text(
            result,
            style: Theme.of(context).textTheme.displayMedium,
          ),
        ])),
        floatingActionButton: FloatingActionButton(
            onPressed: () {
              input = Query(query: textController.text);
              _callGrpcService();
            },
            child: const Icon(Icons.play_arrow)));
  }
}
