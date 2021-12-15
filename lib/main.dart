import 'dart:core';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/call_sample/call_sample.dart';
import 'src/call_sample/data_channel_sample.dart';
import 'src/route_item.dart';

void main(List<String> args) {
  // -id lzjy123
  // -isTeacher 1
  print(args.toString());
  String? id;
  bool? isTeacher;
  args = args[0].split(" ");
  for (var i = 0; i < args.length; i++) {
    print("$i: ${args[i]}\r\n");
    if (args[i] == "-id" && i + 1 < args.length) {
      id = args[i + 1];
    }
  }
  for (var i = 0; i < args.length; i++) {
    if (args[i] == "-isTeacher" && i + 1 < args.length) {
      isTeacher = args[i + 1] == "1";
    }
  }
  if (id == null || isTeacher == null) {
    print("bad request: $id, $isTeacher");
    return;
  }

  runApp(new MyApp(
    id: id,
    isTeacher: isTeacher,
  ));
}

class MyApp extends StatefulWidget {
  final String id;
  final bool isTeacher;

  MyApp({required this.id, required this.isTeacher});

  @override
  _MyAppState createState() => new _MyAppState();
}

enum DialogDemoAction {
  cancel,
  connect,
}

class _MyAppState extends State<MyApp> {
  List<RouteItem> items = [];
  String _server = '10.18.38.203';
  late SharedPreferences _prefs;

  bool _datachannel = false;

  @override
  initState() {
    super.initState();
    _initData();
    // _initItems();
    // _showFindPeer(this.context, widget.id);
  }

  // _buildRow(context, item) {
  //   return ListBody(children: <Widget>[
  //     ListTile(
  //       title: Text(item.title),
  //       onTap: () => item.push(context),
  //       trailing: Icon(Icons.arrow_right),
  //     ),
  //     Divider()
  //   ]);
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            // appBar: AppBar(
            //   title: Text('Flutter-WebRTC example'),
            // ),
            body: CallSample(
      host: _server,
      id: widget.id,
      isTeacher: widget.isTeacher,
    ))
        // body: _showFindPeer(context),
        );
  }

  /// 初始化数据? 服务器host
  _initData() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _server = _prefs.getString('server') ?? 'demo.cloudwebrtc.com';
    });
  }

  /// 服务器信息设置完到这里了
  void showDemoDialog<T>(
      {required BuildContext context, required Widget child}) {
    showDialog<T>(
      context: context,
      builder: (BuildContext context) => child,
    ).then<void>((T? value) {
      // The value passed to Navigator.pop() or null.
      if (value != null) {
        /// 如果是连接的话
        // if (value == DialogDemoAction.connect) {
        //   _prefs.setString('server', _server);
        //   Navigator.push(
        //       context,
        //       MaterialPageRoute(
        //           builder: (BuildContext context) => _datachannel
        //               ? DataChannelSample(host: _server)
        //               : CallSample(
        //                   host: _server,
        //                   targetId: "lzjy123",
        //                 )));
        // }
      }
    });
  }

  /// 显示服务器地址
// _showAddressDialog(context) {
//   showDemoDialog<DialogDemoAction>(
//       context: context,
//       child: AlertDialog(
//           title: const Text('Enter server address:'),
//           content: TextField(
//             onChanged: (String text) {
//               setState(() {
//                 _server = text;
//               });
//             },
//             decoration: InputDecoration(
//               hintText: _server,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           actions: <Widget>[
//             FlatButton(
//                 child: const Text('CANCEL'),
//                 onPressed: () {
//                   Navigator.pop(context, DialogDemoAction.cancel);
//                 }),
//             FlatButton(
//                 child: const Text('CONNECT'),
//                 onPressed: () {
//                   Navigator.pop(context, DialogDemoAction.connect);
//                 })
//           ]));
// }

  /// 查找特定id的peer
// _showFindPeer(context, String id) {
//   Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(
//           builder: (BuildContext context) => CallSample(
//                 host: _server,
//                 targetId: id,
//               )),
//       (route) => route == null);
// }

  ///初始化导航数据
// _initItems() {
//   // items = <RouteItem>[
//   //   RouteItem(
//   //       title: 'P2P Call Sample',
//   //       subtitle: 'P2P Call Sample.',
//   //       push: (BuildContext context) {
//   //         _datachannel = false;
//   //         _showFindPeer(context);
//   //       }),
//   items = <RouteItem>[
//     RouteItem(
//         title: 'P2P Call Sample',
//         subtitle: 'P2P Call Sample.',
//         push: (BuildContext context) {
//           _datachannel = false;
//           _showFindPeer(context, widget.id);
//         }),
//     // RouteItem(
//     //     title: 'Data Channel Sample',
//     //     subtitle: 'P2P Data Channel.',
//     //     push: (BuildContext context) {
//     //       _datachannel = true;
//     //       _showAddressDialog(context);
//     //     }),
//   ];
// }
}
