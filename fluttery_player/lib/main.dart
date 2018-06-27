import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttery_player/bottom_controls.dart';
import 'package:fluttery_player/songs.dart';
import 'package:fluttery_player/theme.dart';
import 'package:fluttery/gestures.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  MyApp();

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fluttery Player',
      home: new _MyHomePage(),
    );
  }
}

class _MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<_MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        leading: new IconButton(
          icon: new Icon(Icons.arrow_back),
          onPressed: () {
            //TODO
          },
          color: Colors.grey[350],
        ),
        actions: <Widget>[
          new IconButton(
            icon: new Icon(Icons.menu),
            onPressed: () {
              //TODO
            },
            color: Colors.grey[350],
          ),
        ],
        title: new Text(''),
      ),
      body: new Column(
        children: <Widget>[
          // seek bar
          new Expanded(child: new RadialSeekBar()),

          // visualizer
          new Container(
            width: double.infinity,
            height: 125.0,
          ),

          //song track and title
          new BottomControls()
        ],
      ),
    );
  }
}

class RadialProgressBar extends StatefulWidget {
  final double trackWidth;
  final Color trackColor;
  final double progressWidth;
  final Color progressColor;
  final double progressPercentage;
  final double thumbSize;
  final Color thumbColor;
  final double thumbPosition;
  final EdgeInsets outPadding;
  final EdgeInsets inPadding;

  final Widget child;

  RadialProgressBar(
      {this.trackWidth = 3.0,
      this.trackColor = Colors.grey,
      this.progressWidth = 5.0,
      this.progressColor = darkAccentColor,
      this.progressPercentage = 0.0,
      this.thumbSize = 10.0,
      this.thumbColor = darkAccentColor,
      this.thumbPosition = 0.0,
      this.outPadding = const EdgeInsets.all(0.0),
      this.inPadding = const EdgeInsets.all(0.0),
      this.child});

  @override
  _RadialProgressBarState createState() => _RadialProgressBarState();
}

class _RadialProgressBarState extends State<RadialProgressBar> {
  EdgeInsets _insetsForPainter() {
    /*
    * Make room for painted track, progress, and thumb. We divide by 2.0 because
    * we want to allow flush painting against track, so we need to account the thickness
    * outside the track , not inside
    * */

    final outThickness =
        max(widget.trackWidth, max(widget.thumbSize, widget.progressWidth)) /
            2.0;
    return new EdgeInsets.all(outThickness);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.outPadding,
      child: new CustomPaint(
        foregroundPainter: new RadiusSeekBarPainter(
            trackColor: widget.trackColor,
            trackWidth: widget.trackWidth,
            progressColor: widget.progressColor,
            progressPercentage: widget.progressPercentage,
            progressWidth: widget.progressWidth,
            thumbColor: widget.thumbColor,
            thumbPosition: widget.thumbPosition,
            thumbSize: widget.thumbSize),
        child: new Padding(
          padding: _insetsForPainter() + widget.inPadding,
          child: widget.child, // child is album art
        ),
      ),
    );
  }
}

class RadiusSeekBarPainter extends CustomPainter {
  final double trackWidth;
  Color trackColor;
  final Paint trackPaint;
  final double progressWidth;
  Color progressColor;
  final double progressPercentage;
  final Paint progressPaint;
  final double thumbSize;
  Color thumbColor;
  final double thumbPosition;
  final Paint thumbPaint;

  RadiusSeekBarPainter(
      {@required this.trackWidth,
      @required trackColor,
      @required this.progressWidth,
      @required progressColor,
      @required this.progressPercentage,
      @required this.thumbSize,
      @required thumbColor,
      @required this.thumbPosition})
      : trackPaint = new Paint()
          ..color = trackColor
          ..strokeWidth = trackWidth
          ..style = PaintingStyle.stroke,
        progressPaint = new Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = progressWidth
          ..color = progressColor
          ..strokeCap = StrokeCap.round,
        thumbPaint = new Paint()
          ..color = thumbColor
          ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final outThickness = max(trackWidth, max(progressWidth, thumbSize));

    final constrainedSize =
        new Size(size.width - outThickness, size.height - outThickness);

    final center = new Offset(size.height / 2, size.width / 2);
    final radius = min(constrainedSize.width, constrainedSize.height) / 2;

    // Paint Track
    canvas.drawCircle(center, radius, trackPaint);

    //Paint Progress
    final progressAngle =
        2 * pi * progressPercentage; // with reference to start angle
    canvas.drawArc(new Rect.fromCircle(center: center, radius: radius), -pi / 2,
        progressAngle, false, progressPaint);

    //Paint thumb
    final thumbAngle = 2 * pi * thumbPosition - pi / 2; // Absolute Angle
    final thumbX = cos(thumbAngle) * radius;
    final thumbY = sin(thumbAngle) * radius;
    final thumbCenter = new Offset(thumbX, thumbY) + center;
    canvas.drawCircle(thumbCenter, thumbSize / 2, thumbPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class RadialSeekBar extends StatefulWidget {
  final double seekPercent;

  RadialSeekBar({this.seekPercent=0.0});

  @override
  _RadialSeekBarState createState() => _RadialSeekBarState();
}

class _RadialSeekBarState extends State<RadialSeekBar> {
  double _seekPercent = 0.0;
  PolarCoord _startDragCoord;
  double _startDragPercent;
  double _currentDragPercent;


  @override
  void initState() {
    super.initState();
    _seekPercent=widget.seekPercent;
  }

  @override
  void didUpdateWidget(RadialSeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _seekPercent=widget.seekPercent;
  }

  void _onRadialDragStart(PolarCoord coord) {
    _startDragCoord = coord;
    _startDragPercent = _seekPercent;
  }

  void _onRadialDragUpdate(PolarCoord coord) {
    final dragAngle = coord.angle - _startDragCoord.angle;
    final dragPercent = dragAngle / (2 * pi);

    setState(
        () => _currentDragPercent = (_startDragPercent + dragPercent) % 1.0);
  }

  void _onRadialDragEnd() {
    setState(() {
      _seekPercent = _currentDragPercent;
      _currentDragPercent = null;
      _startDragCoord = null;
      _startDragPercent = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new RadialDragGestureDetector(
      onRadialDragStart: _onRadialDragStart,
      onRadialDragUpdate: _onRadialDragUpdate,
      onRadialDragEnd: _onRadialDragEnd,
      child: new Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.transparent,
        child: new Center(
          child: new Container(
            width: 140.0,
            height: 140.0,
            child: new RadialProgressBar(
              trackColor: const Color(0xFFDDDDDD),
              progressPercentage: _currentDragPercent ?? _seekPercent,
              progressColor: accentColor,
              thumbPosition: _currentDragPercent ?? _seekPercent,
              thumbColor: lightAccentColor,
              inPadding: const EdgeInsets.all(10.0),
              child: new ClipOval(
                clipper: new CircleClipper(),
                child: new Image.network(
                  demoPlaylist.songs[0].albumArtUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CircleClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return new Rect.fromCircle(
      center: new Offset(size.width / 2, size.height / 2),
      radius: min(size.width, size.height) / 2,
    );
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return true;
  }
}
