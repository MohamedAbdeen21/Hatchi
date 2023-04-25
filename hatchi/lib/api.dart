import 'dart:io';
import 'package:grpc/grpc.dart';

import 'proto/connectors.pbgrpc.dart';

const String socket = "/tmp/test.socket";

String home = Directory(Platform.script.path).parent.path;

initGRPCServer() async {
  // fetch the root of the project, use env variable when testing
  String home = const String.fromEnvironment("HATCHI_HOME");
  if (home.isEmpty) {
    home = Directory(Platform.script.path).parent.path;
  }

  // check if socket is binded, close if true
  if (File(socket).existsSync()) {
    File(socket).delete();
  }

  // start the Go gRPC server, creates socket by default
  var server =
      await Process.start("./server", [], workingDirectory: "$home/backend/");
  stdout.addStream(server.stdout);
  stderr.addStream(server.stderr);
}

// start the gRPC client over UDS and without TLS
DatabaseConnectClient api = DatabaseConnectClient(ClientChannel(
    InternetAddress(socket, type: InternetAddressType.unix),
    options: const ChannelOptions(credentials: ChannelCredentials.insecure())));

// Future<Empty> initConnector(String name) async {
// // server initially have nil database
// return await api.selectConnector(ConnectorName(name: name)).then(
// (options) => api.connect(ConnectionOptions(connectorName: name, fields: [
// ConnectionOptionField(
// name: options.fields[0].name,
// require: options.fields[0].require,
// value: ":memory")
// ])));
// }

// send to gRPC and return Future of result
Future<String> callGrpcService(String query) {
  // const String connector = "sqlite";
  // return initConnector(connector)
  // .then((_) =>
  return api.execute(Query(query: query)).then(
      (response) => response.result.map((e) => e.row.join(" ")).join('\n'));
}

Future<List<String>> listConnectors() {
  return api.listConnectors(Empty()).then((connectors) => connectors.names);
}
