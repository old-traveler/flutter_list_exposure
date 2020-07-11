import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter 元素曝光',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            ListTile(
              title: Text('垂直方向ListView'),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        ExposureDemo(isList: true, axis: Axis.vertical)));
              },
            ),
            ListTile(
              title: Text('水平方向ListView'),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        ExposureDemo(isList: true, axis: Axis.horizontal)));
              },
            ),
            ListTile(
              title: Text('垂直方向GridView'),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        ExposureDemo(isList: false, axis: Axis.vertical)));
              },
            ),
            ListTile(
              title: Text('水平方向GridView'),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        ExposureDemo(isList: false, axis: Axis.horizontal)));
              },
            )
          ],
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class ExposureDemo extends StatelessWidget {
  final bool isList;
  final Axis axis;
  GlobalKey<_ExposureTipState> globalKey = GlobalKey();
  ScrollController _scrollController = ScrollController();

  ExposureDemo({Key key, this.isList, this.axis}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (isList) {
      child = ListView.builder(
        controller: _scrollController,
        itemBuilder: _onItemBuilder,
        scrollDirection: axis,
        itemCount: 200,
      );
    } else {
      child = GridView.builder(
        controller: _scrollController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        scrollDirection: axis,
        itemBuilder: _onItemBuilder,
        itemCount: 100,
      );
    }
    child = ExposureListener(
      child: Column(
        children: <Widget>[
          ExposureTip(
            scrollController: _scrollController,
            key: globalKey,
          ),
          Expanded(
            child: child,
          )
        ],
      ),
      scrollDirection: axis,
      callback: (first, last, notice) {
        globalKey.currentState.updateExposureTip(first, last);
      },
    );
    return Scaffold(
      appBar: AppBar(
        title: Text('元素曝光Demo'),
      ),
      body: child,
    );
  }

  Widget _onItemBuilder(BuildContext context, int index) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 1.0),
          color: Colors.blue),
      height: Random().nextInt(50) + 50.0,
      width: Random().nextInt(50) + 50.0,
      child: Text(
        '$index',
        style: TextStyle(
            color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class ExposureTip extends StatefulWidget {
  final ScrollController scrollController;

  const ExposureTip({Key key, this.scrollController}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ExposureTipState();
  }
}

class _ExposureTipState extends State<ExposureTip> {
  int first;
  int last;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.scrollController.jumpTo(0.1);
      widget.scrollController.jumpTo(0.0);
    });
  }

  void updateExposureTip(int first, int last) {
    setState(() {
      this.first = first;
      this.last = last;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      alignment: Alignment.center,
      child: Text.rich(TextSpan(children: <InlineSpan>[
        TextSpan(text: '当前第一个完全可见元素下标:'),
        TextSpan(
            text: '$first \n',
            style: TextStyle(
                color: Colors.red, fontSize: 15, fontWeight: FontWeight.bold)),
        TextSpan(text: '当前最后一个完全可见元素下标:'),
        TextSpan(
            text: '$last ',
            style: TextStyle(
                color: Colors.red, fontSize: 15, fontWeight: FontWeight.bold)),
      ])),
    );
  }
}

typedef ExposureCallback = void Function(
    int firstIndex, int lastIndex, ScrollNotification scrollNotification);

class ExposureListener extends StatelessWidget {
  final Widget child;

  // 可不填写
  final GlobalKey sliverKey;
  final ExposureCallback callback;
  final Axis scrollDirection;

  const ExposureListener(
      {Key key,
      this.child,
      this.sliverKey,
      this.callback,
      this.scrollDirection})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NotificationListener(child: child, onNotification: _onNotification);
  }

  bool _onNotification(ScrollNotification notice) {
    final sliverMultiBoxAdaptorElement = findSliverMultiBoxAdaptorElement(
        sliverKey?.currentContext ?? notice.context);
    assert(sliverMultiBoxAdaptorElement != null);
    int firstIndex = sliverMultiBoxAdaptorElement.childCount;
    assert(firstIndex != null);
    int endIndex = -1;
    void onVisitChildren(Element element) {
      final SliverMultiBoxAdaptorParentData oldParentData =
          element?.renderObject?.parentData;
      if (oldParentData != null) {
        double boundFirst = oldParentData.layoutOffset;
        double itemLength = scrollDirection == Axis.vertical
            ? element.renderObject.paintBounds.height
            : element.renderObject.paintBounds.width;
        double boundEnd = itemLength + boundFirst;
        if (boundFirst >= notice.metrics.pixels &&
            boundEnd <=
                (notice.metrics.pixels + notice.metrics.viewportDimension)) {
          firstIndex = min(firstIndex, oldParentData.index);

          endIndex = max(endIndex, oldParentData.index);
        }
      }
    }

    sliverMultiBoxAdaptorElement.visitChildren(onVisitChildren);
    callback(firstIndex, endIndex, notice);
    return false;
  }

  SliverMultiBoxAdaptorElement findSliverMultiBoxAdaptorElement(
      Element element) {
    if (element is SliverMultiBoxAdaptorElement) {
      return element;
    }
    SliverMultiBoxAdaptorElement target;
    element.visitChildElements((child) {
      target ??= findSliverMultiBoxAdaptorElement(child);
    });
    return target;
  }
}
