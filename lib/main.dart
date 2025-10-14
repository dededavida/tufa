import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle Estufa',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const BluetoothPage(),
    );
  }
}

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  BluetoothConnection? connection;
  bool connected = false;
  String status = "Desconectado";
  String receivedData = "";

  @override
  void initState() {
    super.initState();
    initBluetooth();
  }

  Future<void> initBluetooth() async {
    try {
      // Solicitar permissões Bluetooth (Android 12+)
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      // Verificar se todas as permissões foram concedidas
      bool allGranted = statuses.values.every((status) => status.isGranted);
      
      if (!allGranted) {
        setState(() => status = "Permissões negadas. Ative-as nas configurações.");
        return;
      }

      // Descobrir dispositivos emparelhados
      List<BluetoothDevice> devices =
          await FlutterBluetoothSerial.instance.getBondedDevices();

      debugPrint("fasfsafasfas");
      debugPrint(devices.toString());

      debugPrint('fasfas');

      debugPrint(devices.toString());

      // Procura pelo HC-05
      BluetoothDevice? hc05;
      for (var device in devices) {
        if (device.name == "HC-05") {
          hc05 = device;
          break;
        }
      }

      if (hc05 == null) {
        setState(() => status = "HC-05 não encontrado!");
        return;
      }

      // Conectar
      connection = await BluetoothConnection.toAddress(hc05.address);
      setState(() {
        connected = true;
        status = "Conectado a ${hc05?.name}";
      });

      connection!.input?.listen(
        (data) {
          setState(() {
            receivedData = String.fromCharCodes(data);
          });
        },
        onDone: () {
          setState(() {
            connected = false;
            status = "Desconectado";
          });
        },
      );
    } catch (e) {
      setState(() => status = "Erro de conexão: $e");
    }
  }

  void sendCommand(String cmd) {
    if (connected && connection != null) {
      connection!.output.add(Uint8List.fromList(cmd.codeUnits));
      connection!.output.allSent;
      setState(() {
        status = "Enviado: $cmd";
      });
    } else {
      setState(() {
        status = "Dispositivo não conectado";
      });
    }
  }

  @override
  void dispose() {
    connection?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Estufa Inteligente")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(status, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text(
              "Recebido: $receivedData",
              style: const TextStyle(color: Colors.blue),
            ),
            const SizedBox(height: 30),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(
                  onPressed: () => sendCommand('L'),
                  child: const Text("Ligar Lâmpada"),
                ),
                ElevatedButton(
                  onPressed: () => sendCommand('D'),
                  child: const Text("Desligar Lâmpada"),
                ),
                ElevatedButton(
                  onPressed: () => sendCommand('C'),
                  child: const Text("Ligar Cooler"),
                ),
                ElevatedButton(
                  onPressed: () => sendCommand('F'),
                  child: const Text("Desligar Cooler"),
                ),
                ElevatedButton(
                  onPressed: () => sendCommand('A'),
                  child: const Text("Modo Automático"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
