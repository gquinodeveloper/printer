import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:typed_data';
import 'package:test_impresora_v2/printerenum.dart';

import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class PrinterView extends StatefulWidget {
  const PrinterView({Key? key}) : super(key: key);

  @override
  _PrinterViewState createState() => _PrinterViewState();
}

class _PrinterViewState extends State<PrinterView> {
  BlueThermalPrinter bluetoothPrinter = BlueThermalPrinter.instance;

  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _device;
  bool _connected = false;
  TestPrint testPrint = TestPrint();
  String pathImage = "";

  @override
  void initState() {
    super.initState();
    initPlatformState();
    initSavetoPath();
  }

  Future<void> initPlatformState() async {
    bool? isConnected = await bluetoothPrinter.isConnected;
    List<BluetoothDevice> devices = [];
    try {
      devices = await bluetoothPrinter.getBondedDevices();
    } on PlatformException {}

    bluetoothPrinter.onStateChanged().listen((state) {
      switch (state) {
        case BlueThermalPrinter.CONNECTED:
          setState(() {
            _connected = true;
            print("bluetooth device state: connected");
          });
          break;
        case BlueThermalPrinter.DISCONNECTED:
          setState(() {
            _connected = false;
            print("bluetooth device state: disconnected");
          });
          break;
        case BlueThermalPrinter.DISCONNECT_REQUESTED:
          setState(() {
            _connected = false;
            print("bluetooth device state: disconnect requested");
          });
          break;
        case BlueThermalPrinter.STATE_TURNING_OFF:
          setState(() {
            _connected = false;
            print("bluetooth device state: bluetooth turning off");
          });
          break;
        case BlueThermalPrinter.STATE_OFF:
          setState(() {
            _connected = false;
            print("bluetooth device state: bluetooth off");
          });
          break;
        case BlueThermalPrinter.STATE_ON:
          setState(() {
            _connected = false;
            print("bluetooth device state: bluetooth on");
          });
          break;
        case BlueThermalPrinter.STATE_TURNING_ON:
          setState(() {
            _connected = false;
            print("bluetooth device state: bluetooth turning on");
          });
          break;
        case BlueThermalPrinter.ERROR:
          setState(() {
            _connected = false;
            print("bluetooth device state: error");
          });
          break;
        default:
          print(state);
          break;
      }
    });

    if (!mounted) return;
    setState(() {
      _devices = devices;
    });

    if (isConnected == true) {
      setState(() {
        _connected = true;
      });
    }
  }

  Future<String> _downloadImage() async {
    try {
      // Obtener la ruta del directorio de almacenamiento local en el dispositivo
      final appDirectory = await getApplicationDocumentsDirectory();
      final downloadDirectory = '${appDirectory.path}/oli';

      // Verificar si el directorio de descarga existe, si no, crearlo
      final directory = Directory(downloadDirectory);
      if (!await directory.exists()) {
        await directory.create();
      }

      // Cargar el archivo de imagen del asset como un Uint8List
      final imageData = await rootBundle.load('assets/logo2.png');
      final bytes = imageData.buffer.asUint8List();

      // Crear el archivo de imagen en el directorio de descarga
      final file = File('$downloadDirectory/logo2.png');
      await file.writeAsBytes(bytes);

      return file.path;
    } catch (e) {
      print(e);
      return Future.delayed(Duration());
    }
  }

  static Future<Uint8List> downloadFile(String url, fileName) async {
    Uint8List uint8list = Uint8List(0);
    String savePath = await getFilePath(fileName);
    Dio dio = Dio();
    await dio.download(
      url,
      savePath,
      onReceiveProgress: (rcv, total) async {
        uint8list = Uint8List.fromList(File(savePath).readAsBytesSync());
      },
      deleteOnError: true,
    );

    return uint8list;
  }

  static Future<String> getFilePath(fileName) async {
    String path = '';
    Directory dir = await getApplicationDocumentsDirectory();
    path = '${dir.path}/$fileName.pdf';
    print(path);
    return path;
  }

  initSavetoPath() async {
    //read and write
    //image max 300px X 300px
    final filename = 'looo.png';
    var bytes = await rootBundle.load("assets/lae.png");
    String dir = (await getApplicationDocumentsDirectory()).path;
    writeToFile(bytes, '$dir/$filename');
    setState(() {
      pathImage = '$dir/$filename';
    });
  }

  //write to app path
  Future<void> writeToFile(ByteData data, String path) {
    final buffer = data.buffer;
    return new File(path).writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  Future<void> _printReceipt() async {
    try {
      await bluetoothPrinter.isConnected; // Verificar si está conectado

      // Iniciar la impresión
      await bluetoothPrinter.printCustom("Nombre de la tienda", 3, 1);
      await bluetoothPrinter.printImage(pathImage);
      await bluetoothPrinter.printNewLine();
      await bluetoothPrinter.printCustom("Fecha: 04/04/2023", 1, 0);

      await bluetoothPrinter.printNewLine();
      await bluetoothPrinter.printCustom(
          "------------------------------", 1, 0);

      await bluetoothPrinter.printNewLine();
      await bluetoothPrinter.printCustom("Producto", 0, 0);
      await bluetoothPrinter.printCustom("Precio", 1, 0);

      await bluetoothPrinter.printNewLine();
      await bluetoothPrinter.printCustom(
          "------------------------------", 1, 0);

      await bluetoothPrinter.printNewLine();
      await bluetoothPrinter.printCustom("Producto 1", 0, 0);
      await bluetoothPrinter.printCustom("\$10.00", 2, 0);

      await bluetoothPrinter.printNewLine();
      await bluetoothPrinter.printCustom("Producto 2", 0, 0);
      await bluetoothPrinter.printCustom("\$20.00", 2, 0);

      await bluetoothPrinter.printNewLine();
      await bluetoothPrinter.printCustom("Producto 3", 0, 0);
      await bluetoothPrinter.printCustom("\$15.00", 2, 0);

      await bluetoothPrinter.printNewLine();
      await bluetoothPrinter.printCustom(
          "------------------------------", 1, 0);

      // Imprimir imagen
      //await bluetoothPrinter.printImage(await _downloadImage());
      /* final logo = await downloadFile(
          "https://laesystems.com/assets/images/laesystems2.png", "logo");
      await bluetoothPrinter.printImageBytes(logo); */

      // Imprimir código QR
      /*   final qrData = "https://www.ejemplo.com";
      final qrCode = QrCode.fromData(data: qrData);
      final qrBytes = Uint8List.fromList(qrCode.toBytes(200, 0));
      await bluetoothPrinter.printImage(qrBytes); */

      await bluetoothPrinter.printNewLine();
      await bluetoothPrinter.printCustom("Total:", 1, 0);
      await bluetoothPrinter.printCustom("\$45.00", 2, 0);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    'Device:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    width: 30,
                  ),
                  Expanded(
                    child: DropdownButton(
                      items: _getDeviceItems(),
                      onChanged: (BluetoothDevice? value) =>
                          setState(() => _device = value),
                      value: _device,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(primary: Colors.brown),
                    onPressed: () {
                      initPlatformState();
                    },
                    child: Text(
                      'Refresh',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        primary: _connected ? Colors.red : Colors.green),
                    onPressed: _connected ? _disconnect : _connect,
                    child: Text(
                      _connected ? 'Disconnect' : 'Connect',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              Padding(
                padding:
                    const EdgeInsets.only(left: 10.0, right: 10.0, top: 50),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(primary: Colors.brown),
                  onPressed: () async {
                    await _printReceipt();
                    //testPrint.sample();
                  },
                  child:
                      Text('PRINT TEST', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devices.isEmpty) {
      items.add(DropdownMenuItem(
        child: Text('NONE'),
      ));
    } else {
      _devices.forEach((device) {
        items.add(DropdownMenuItem(
          child: Text(device.name ?? ""),
          value: device,
        ));
      });
    }
    return items;
  }

  void _connect() async {
    try {
      if (_device != null) {
        bool isConnected = await bluetoothPrinter.connect(
            _device ?? BluetoothDevice("", "")); // Conectar con la impresora
        /* bluetoothPrinter.isConnected.then((isConnected) {
          print("isConnected: $isConnected");
          if (isConnected == true) {
            bluetoothPrinter.connect(_device!).catchError((error) {
              setState(() => _connected = false);
            });
            setState(() => _connected = true);
          } */
        /*  }).onError((error, stackTrace) {
          print("error: $error");
        }); */
      } else {
        show('No device selected.');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void _disconnect() {
    bluetoothPrinter.disconnect();
    setState(() => _connected = false);
  }

  Future show(
    String message, {
    Duration duration: const Duration(seconds: 3),
  }) async {
    await new Future.delayed(new Duration(milliseconds: 100));
    ScaffoldMessenger.of(context).showSnackBar(
      new SnackBar(
        content: new Text(
          message,
          style: new TextStyle(
            color: Colors.white,
          ),
        ),
        duration: duration,
      ),
    );
  }
}

///Test printing
class TestPrint {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

/*   Uint8List _getByteArrayFromImage(String imagePath) {
  File file = File(imagePath);
  List<int> bytes = file.readAsBytesSync();
  Image image = decodeImage(bytes);
  return encodePng(image);
}
 */
  sample() async {
    //image max 300px X 300px

    ///image from File path
    String filename = 'yourlogo.png';
    ByteData bytesData = await rootBundle.load("assets/logo2.png");
    String dir = (await getApplicationDocumentsDirectory()).path;
    File file = await File('$dir/$filename').writeAsBytes(bytesData.buffer
        .asUint8List(bytesData.offsetInBytes, bytesData.lengthInBytes));

    ///image from Asset
/*     ByteData bytesAsset = await rootBundle.load("assets/logo2.png");
    Uint8List imageBytesFromAsset = bytesAsset.buffer
        .asUint8List(bytesAsset.offsetInBytes, bytesAsset.lengthInBytes); */

    ///image from Network
    /*  var response = await http.get(Uri.parse(
        "https://laesystems.com/assets/images/laesystems2.png?ver=2.0"));
    Uint8List bytesNetwork = response.bodyBytes;
    Uint8List imageBytesFromNetwork = bytesNetwork.buffer
        .asUint8List(bytesNetwork.offsetInBytes, bytesNetwork.lengthInBytes); */

    bluetooth.isConnected.then((isConnected) {
      if (isConnected == true) {
        bluetooth.printNewLine();
        bluetooth.printCustom("HEADER", Size.boldMedium.val, Alignx.center.val);
        bluetooth.printNewLine();

        //bluetooth.printImage(file.path); //path of your image/logo
        bluetooth.printNewLine();
        // bluetooth.printImageBytes(imageBytesFromAsset); //image from Asset
        bluetooth.printImage("assets/logo2.png");

        bluetooth.printNewLine();
        //bluetooth.printImageBytes(imageBytesFromNetwork); //image from Network
        bluetooth.printNewLine();
        bluetooth.printLeftRight("LEFT", "RIGHT", Size.medium.val);
        bluetooth.printLeftRight("LEFT", "RIGHT", Size.bold.val);
        bluetooth.printLeftRight("LEFT", "RIGHT", Size.bold.val,
            format:
                "%-15s %15s %n"); //15 is number off character from left or right
        bluetooth.printNewLine();
        bluetooth.printLeftRight("LEFT", "RIGHT", Size.boldMedium.val);
        bluetooth.printLeftRight("LEFT", "RIGHT", Size.boldLarge.val);
        bluetooth.printLeftRight("LEFT", "RIGHT", Size.extraLarge.val);
        bluetooth.printNewLine();
        bluetooth.print3Column("Col1", "Col2", "Col3", Size.bold.val);
        bluetooth.print3Column("Col1", "Col2", "Col3", Size.bold.val,
            format:
                "%-10s %10s %10s %n"); //10 is number off character from left center and right
        bluetooth.printNewLine();
        bluetooth.print4Column("Col1", "Col2", "Col3", "Col4", Size.bold.val);
        bluetooth.print4Column("Col1", "Col2", "Col3", "Col4", Size.bold.val,
            format: "%-8s %7s %7s %7s %n");
        bluetooth.printNewLine();
        bluetooth.printCustom("čĆžŽšŠ-H-ščđ", Size.bold.val, Alignx.center.val,
            charset: "windows-1250");
        bluetooth.printLeftRight("Številka:", "18000001", Size.bold.val,
            charset: "windows-1250");
        bluetooth.printCustom("Body left", Size.bold.val, Alignx.left.val);
        bluetooth.printCustom("Body right", Size.medium.val, Alignx.right.val);
        bluetooth.printNewLine();
        bluetooth.printCustom("Thank You", Size.bold.val, Alignx.center.val);
        bluetooth.printNewLine();
        bluetooth.printQRcode(
            "Insert Your Own Text to Generate", 200, 200, Alignx.center.val);
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth
            .paperCut(); //some printer not supported (sometime making image not centered)
        //bluetooth.drawerPin2(); // or you can use bluetooth.drawerPin5();

        bluetooth.disconnect();
      }
    });
  }

//   sample(String pathImage) async {
//     //SIZE
//     // 0- normal size text
//     // 1- only bold text
//     // 2- bold with medium text
//     // 3- bold with large text
//     //ALIGN
//     // 0- ESC_ALIGN_LEFT
//     // 1- ESC_ALIGN_CENTER
//     // 2- ESC_ALIGN_RIGHT
//
// //     var response = await http.get("IMAGE_URL");
// //     Uint8List bytes = response.bodyBytes;
//     bluetooth.isConnected.then((isConnected) {
//       if (isConnected == true) {
//         bluetooth.printNewLine();
//         bluetooth.printCustom("HEADER", 3, 1);
//         bluetooth.printNewLine();
//         bluetooth.printImage(pathImage); //path of your image/logo
//         bluetooth.printNewLine();
// //      bluetooth.printImageBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
//         bluetooth.printLeftRight("LEFT", "RIGHT", 0);
//         bluetooth.printLeftRight("LEFT", "RIGHT", 1);
//         bluetooth.printLeftRight("LEFT", "RIGHT", 1, format: "%-15s %15s %n");
//         bluetooth.printNewLine();
//         bluetooth.printLeftRight("LEFT", "RIGHT", 2);
//         bluetooth.printLeftRight("LEFT", "RIGHT", 3);
//         bluetooth.printLeftRight("LEFT", "RIGHT", 4);
//         bluetooth.printNewLine();
//         bluetooth.print3Column("Col1", "Col2", "Col3", 1);
//         bluetooth.print3Column("Col1", "Col2", "Col3", 1,
//             format: "%-10s %10s %10s %n");
//         bluetooth.printNewLine();
//         bluetooth.print4Column("Col1", "Col2", "Col3", "Col4", 1);
//         bluetooth.print4Column("Col1", "Col2", "Col3", "Col4", 1,
//             format: "%-8s %7s %7s %7s %n");
//         bluetooth.printNewLine();
//         String testString = " čĆžŽšŠ-H-ščđ";
//         bluetooth.printCustom(testString, 1, 1, charset: "windows-1250");
//         bluetooth.printLeftRight("Številka:", "18000001", 1,
//             charset: "windows-1250");
//         bluetooth.printCustom("Body left", 1, 0);
//         bluetooth.printCustom("Body right", 0, 2);
//         bluetooth.printNewLine();
//         bluetooth.printCustom("Thank You", 2, 1);
//         bluetooth.printNewLine();
//         bluetooth.printQRcode("Insert Your Own Text to Generate", 200, 200, 1);
//         bluetooth.printNewLine();
//         bluetooth.printNewLine();
//         bluetooth.paperCut();
//       }
//     });
//   }
}
