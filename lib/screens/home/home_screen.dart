import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;

  Future getImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    List<List<int>> packet = [];

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);

        //packet = splitFileIntoPackets(_image);
      } else {
        print('No image selected.');
      }
    });

    int index = 0;

    try {
      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        final imageBytes = await imageFile.readAsBytes();
        final chunkSize = 2047;
        print("test1");

        final socket = await Socket.connect("172.20.10.4", 8080);

        socket.write('0start');
        print("test2");

        int i = 0;
        Uint8List chunkWithPrefix = Uint8List.fromList([]);

        socket.listen(
          (Uint8List data) {
            print('Sunucudan gelen veri: ${String.fromCharCodes(data)}');
            final serverResponse = Uint8List.fromList(data)[0] - 48;
            print("server response -> ");
            print(serverResponse);


            if (serverResponse == 31) {
              socket.write("1message");
            } else if (serverResponse == 1 || serverResponse == 0 ) {

              if (i < imageBytes.length) {
                final end = (i + chunkSize < imageBytes.length)
                    ? i + chunkSize
                    : imageBytes.length;
                final chunk = imageBytes.sublist(i, end);

                // Add '1' at the beginning of each chunk, '2' for the last chunk
                final prefix = (end == imageBytes.length)
                    ? Uint8List.fromList([2])
                    : Uint8List.fromList([1]);
                chunkWithPrefix = Uint8List.fromList(prefix + chunk);

                socket.add(chunkWithPrefix);

                print('Sent chunk ${i ~/ chunkSize + 1}');
                i += chunkSize;
              }
            } else if (serverResponse == 2) {
              socket.close();
              print('Finished sending.');
            } else if (serverResponse == 6) {
              socket.write("6Connection Established");
              print("baglandi");
            }
          },
          onError: (error) {
            print('Error: $error');
          },
          onDone: () {
            print('Server closed connection.');
          },
        );
      } else {
        print('No image selected.');
      }
      /*final socket = await Socket.connect('your-server.com', 1234);

        socket.listen(
          (Uint8List data) {
            print('Sunucudan gelen veri: ${String.fromCharCodes(data)}');
          },
          onError: (error) {
            print('Hata oluştu: $error');
            socket.destroy();
          },
          onDone: () {
            print('Bağlantı kapandı');
            socket.destroy();
          },
        );*/

      //final socket = await Socket.connect('192.168.137.109', 8080);
      //socket.write('0start');

      /*

      socket.listen(
        (Uint8List data) {
          print('Sunucudan gelen veri: ${String.fromCharCodes(data)}');
          String dataStr = String.fromCharCodes(data);
          if (dataStr[0] == "0") {
            print("giden veri -> ");
            Uint8List uint8List = Uint8List.fromList(packet[index++]);

            socket.write(uint8List);
          }
          if (dataStr[0] == "1") {
            Uint8List uint8List = Uint8List.fromList(packet[index++]);

            socket.write(uint8List);
          }
          if (dataStr[0] == "2") {
            print("bitti");
            index = 0;
          }
          if (dataStr[0] == "3") {}
        },
        onError: (error) {
          print('Hata oluştu: $error');
          socket.destroy();
        },
        onDone: () {
          print('Bağlantı kapandı');
          socket.destroy();
        },
      );*/

      // runApp çağrısı bağlantı kurulduktan sonra gerçekleşecek
    } catch (e) {
      // Bağlantı hatası durumunda kullanıcıya bildirim göster
      print('Bağlantı hatası: $e');

      // Burada kullanıcıya bir bildirim gösterebilirsiniz, örneğin:
      // showDialog veya snackbar kullanarak bir ileti gösterme
    }
  }

  List<List<int>> splitFileIntoPackets(File? file) {
    if (file != null) {
      List<List<int>> packets = [];
      int chunkSize = 4096 - 1; // 4KB

      List<int> bytes = file.readAsBytesSync();
      int offset = 0;

// 1 , 2 ,3 ,4

      //print("split file into packets start\n");

      while (offset < bytes.length) {
        int end = offset + chunkSize < bytes.length
            ? offset + chunkSize
            : bytes.length;
        List<int> tmp;
        tmp = bytes.sublist(offset, end);
        List<int> reversedNumbers = tmp.reversed.toList();

        reversedNumbers.add(1);

        tmp = reversedNumbers.reversed.toList();

        //tmp.insert(0, 1);
        //packets.add(bytes.sublist(offset, end));
        packets.add(tmp);
        offset = end;
        //print("length -> \n");

        //String asciiString = String.fromCharCodes(tmp);
        Uint8List uint8List = Uint8List.fromList(tmp);

        //print(uint8List);
        //sleep(Duration(seconds: 5));
      }
      List<int> tmp2 = packets.last.reversed.toList();
      tmp2.removeLast();
      tmp2.add(2);
      //print("tmp2 -> ");
      //print(tmp2);
      packets.removeLast();
      tmp2 = tmp2.reversed.toList();
      packets.add(tmp2);

      //print("last->\n");
      //print(packets.last);
      //print("son test -> ");
      //print(packets[4]);

      //print("split file into packets end\n");
      return packets;
    } else {
      print('File is null.');
      List<List<int>> packets = [];
      return packets;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Image Page'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _image == null ? Text('No image selected.') : Image.file(_image!),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  getImage(ImageSource.gallery);
                },
                child: Text('Galeri'),
              ),
              ElevatedButton(
                onPressed: () {
                  getImage(ImageSource.camera);
                },
                child: Text('Kamera'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
