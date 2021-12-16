import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:core';
import 'signaling.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallSample extends StatefulWidget {
  static String tag = 'call_sample';
  final String host;
  final String id;
  final bool isTeacher;

  CallSample({required this.host, required this.id, required this.isTeacher});

  @override
  _CallSampleState createState() => _CallSampleState();
}

class _CallSampleState extends State<CallSample> {
  Signaling? _signaling;
  List<dynamic> _peers = [];
  dynamic _targetPeer;
  String? _selfId;
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _inCalling = false;
  Session? _session;

  // ignore: unused_element
  _CallSampleState();

  @override
  initState() {
    super.initState();
    initRenderers();
    _connect();
    // 直接连接 不行 消息还没拿到
    // _invitePeer(context, _targetPeer["id"], false);
  }

  /// 初始化渲染器
  initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  @override
  deactivate() {
    super.deactivate();
    _signaling?.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
  }

  /// 连接ws _signaling的状态处理
  void _connect() async {
    // 连接host的8086端口的/ws
    // 如果是教师 给自己设置id
    if (widget.isTeacher) {
      _signaling ??= Signaling.setId(widget.host, widget.id)..connect();
    } else {
      _signaling ??= Signaling(widget.host)..connect();
    }
    // 啥也没干
    _signaling?.onSignalingStateChange = (SignalingState state) {
      switch (state) {
        case SignalingState.ConnectionClosed:
        case SignalingState.ConnectionError:
        case SignalingState.ConnectionOpen:
          break;
      }
    };

    // 状态处理
    _signaling?.onCallStateChange = (Session session, CallState state) {
      switch (state) {
        case CallState.CallStateNew:
          setState(() {
            _session = session;
            _inCalling = true;
          });
          break;
        case CallState.CallStateBye:
          setState(() {
            _localRenderer.srcObject = null;
            _remoteRenderer.srcObject = null;
            _inCalling = false;
            _session = null;
          });
          break;
        case CallState.CallStateInvite:
        case CallState.CallStateConnected:
        case CallState.CallStateRinging:
      }
    };

    _signaling?.onPeersUpdate = ((event) {
      setState(() {
        // 是教师 自身id
        _selfId = widget.isTeacher ? widget.id : event['self'];
        _peers = event['peers'];
        print("peers: $_peers");
        for (var peer in _peers) {
          // 不是教师 连接
          if (!widget.isTeacher) {
            // id是目标id
            if (peer['id'] == widget.id) {
              _targetPeer = peer;
              if (_targetPeer != null) {
                _invitePeer(context, _targetPeer["id"], false);
              }
              break;
            }
          }
        }
      });
    });

    _signaling?.onLocalStream = ((stream) {
      if (stream != null) {
        _localRenderer.srcObject = stream;
      }
    });

    _signaling?.onAddRemoteStream = ((_, stream) {
      _remoteRenderer.srcObject = stream;
    });

    _signaling?.onRemoveRemoteStream = ((_, stream) {
      _remoteRenderer.srcObject = null;
    });
  }

  /// invite
  _invitePeer(BuildContext context, String peerId, bool useScreen) async {
    print("_invitePeer $peerId");
    if (_signaling != null && peerId != _selfId) {
      _signaling?.invite(peerId, 'video', useScreen);
    }
  }

  _hangUp() {
    if (_session != null) {
      _signaling?.bye(_session!.sid);
    }
  }

  _switchCamera() {
    _signaling?.switchCamera();
  }

  _muteMic() {
    _signaling?.muteMic();
  }

  // 生成客户端列表
  _buildRow(context, peer) {
    var self = (peer['id'] == _selfId);
    return ListBody(children: <Widget>[
      ListTile(
        title: Text(self
            ? peer['name'] + ', ID: ${peer['id']} ' + ' [Your self]'
            : peer['name'] + ', ID: ${peer['id']} '),
        onTap: null,
        trailing: SizedBox(
            width: 100.0,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    icon: Icon(self ? Icons.close : Icons.videocam,
                        color: self ? Colors.grey : Colors.black),
                    onPressed: () => _invitePeer(context, peer['id'], false),
                    tooltip: 'Video calling',
                  ),
                  IconButton(
                    icon: Icon(self ? Icons.close : Icons.screen_share,
                        color: self ? Colors.grey : Colors.black),
                    onPressed: () => _invitePeer(context, peer['id'], true),
                    tooltip: 'Screen sharing',
                  )
                ])),
        subtitle: Text('[' + peer['user_agent'] + ']'),
      ),
      Divider()
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('P2P Call Sample' +
              (_selfId != null ? ' [Your ID ($_selfId)] ' : '')),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: null,
              tooltip: 'setup',
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _inCalling
            ? SizedBox(
                width: 200.0,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      // FloatingActionButton(
                      //   child: const Icon(Icons.switch_camera),
                      //   onPressed: _switchCamera,
                      // ),
                      FloatingActionButton(
                        onPressed: _hangUp,
                        tooltip: 'Hangup',
                        child: Icon(Icons.call_end),
                        backgroundColor: Colors.pink,
                      ),
                      FloatingActionButton(
                        child: const Icon(Icons.mic_off),
                        onPressed: _muteMic,
                      )
                    ]))
            : null,
        body: _inCalling
            ? OrientationBuilder(builder: (context, orientation) {
                // 这个是画面?
                return Container(
                  child: Stack(children: <Widget>[
                    Positioned(
                        left: 0.0,
                        right: 0.0,
                        top: 0.0,
                        bottom: 0.0,
                        child: Container(
                          margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                          child: RTCVideoView(_remoteRenderer),
                          decoration: BoxDecoration(color: Colors.black54),
                        )),
                    // Positioned(
                    //   left: 20.0,
                    //   top: 20.0,
                    //   child: Container(
                    //     width:
                    //         orientation == Orientation.portrait ? 90.0 : 120.0,
                    //     height:
                    //         orientation == Orientation.portrait ? 120.0 : 90.0,
                    //     child: RTCVideoView(_localRenderer, mirror: true),
                    //     decoration: BoxDecoration(color: Colors.black54),
                    //   ),
                    // ),
                  ]),
                );
              })
            // 搞个友好提示
            : Container(
                child: Text("等待连接中..."),
              ));
  }
}
