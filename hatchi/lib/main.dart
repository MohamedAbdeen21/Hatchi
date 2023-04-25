import 'package:client/proto/connectors.pb.dart';
import 'package:flutter/material.dart';
import 'api.dart';

const secondaryColor = Colors.blue;
const secondaryShade = 800;

void main() {
  initGRPCServer();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        title: "Hatchi", home: MyHomePage(title: "Hatchi"));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController textController = TextEditingController();

  // final GlobalKey<ScaffoldState> _key = GlobalKey();
  //
  // void _listOptions(String connectorName) {
  //   api.selectConnector(ConnectorName(name: connectorName))
  //     .then((options) => options.fields.map((field) => { print(field.name) }));
  // }

  void _callGrpc(String query) async {
    result = await callGrpcService(query);
  }

  String result = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Hatchi"),
          backgroundColor: secondaryColor[secondaryShade],
        ),
        drawer: const ConnectorsDrawer(),
        body: Center(
            child: Column(children: <Widget>[
          TextFormField(
            controller: textController,
            decoration: InputDecoration(
                filled: true,
                hintText: "Enter SQL Query",
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
              setState(() {
                _callGrpc(textController.text);
              });
            },
            child: const Icon(Icons.play_arrow)));
  }
}

class ConnectorsDrawer extends StatelessWidget {
  const ConnectorsDrawer({Key? key}) : super(key: key);

  Future<List<Card>> buildConnectorsMenu(BuildContext context) async {
    List<Card> tiles = [];
    for (var connector in await listConnectors()) {
      tiles.add(Card(
          child: ListTile(
        leading: const Icon(Icons.dataset),
        onTap: () {
          Navigator.pop(context);
          Popup().connectorPopup(context, connector);
        },
        contentPadding: const EdgeInsets.all(20),
        title: Text(connector, style: Theme.of(context).textTheme.titleLarge),
      )));
    }

    return tiles;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: FutureBuilder<List<Widget>>(
            future: buildConnectorsMenu(context),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const CircularProgressIndicator();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: snapshot.data?.length,
                itemBuilder: (context, index) {
                  return snapshot.data?[index];
                },
              );
            }));
  }
}

class Popup {
  Map<ConnectionOptionField, TextEditingController> controllers = {};

  List<Widget> listOptions(ConnectionOptions options) {
    return options.fields.map((field) {
      TextEditingController textController = TextEditingController();
      controllers[field] = textController;
      return Card(
          child: ListTile(
              leading: Text(field.name),
              trailing: Text(field.require ? "*" : "",
                  style: const TextStyle(color: Colors.red)),
              title: TextFormField(
                controller: textController,
                validator: (value) {
                  if (field.require && (value == null || value.isEmpty)) {
                    return "Field is required";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: field.type,
                  filled: true,
                  fillColor: Colors.black12, // 12 is opacity
                  contentPadding: const EdgeInsets.fromLTRB(30, 8, 30, 10),
                  // border: OutlineInputBorder(
                  //     borderSide: BorderSide.none,
                  // borderRadius: BorderRadius.circular(20)
                  // )
                ),
              )));
    }).toList();
  }

  List<ElevatedButton> createButtons(BuildContext context, String connector) {
    ButtonStyle style = ButtonStyle(
        backgroundColor:
            MaterialStatePropertyAll(secondaryColor[secondaryShade]),
        padding: const MaterialStatePropertyAll(
            EdgeInsets.fromLTRB(25, 20, 25, 20)));

    return [
      ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: style,
          child: const Text("Cancel")),
      ElevatedButton(
        style: style,
        onPressed: () {
          controllers
              .forEach((field, controller) => field.value = controller.text);
          api.connect(ConnectionOptions(
            connectorName: connector,
            fields: controllers.keys,
          ));
          Navigator.pop(context);
        },
        child: const Text("Connect"),
      )
    ];
  }

  Future<dynamic> connectorPopup(BuildContext context, String connector) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return FutureBuilder(
              future: api.selectConnector(ConnectorName(name: connector)),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const CircularProgressIndicator();
                }
                return AlertDialog(
                  title: Text("Connecting to $connector"),
                  content: ConstrainedBox(
                    constraints: const BoxConstraints(
                        minWidth: 600,
                        maxWidth: 600,
                        maxHeight: 800,
                        minHeight: 800),
                    child: ListView(
                        padding: const EdgeInsets.all(5),
                        children: listOptions(snapshot.data!)),
                  ),
                  actions: createButtons(context, connector),
                );
              });
        });
  }
}
