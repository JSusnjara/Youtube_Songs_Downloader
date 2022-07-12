import 'package:flutter/material.dart';
import 'package:yt_songs/local_data.dart';

class LoadingScreen extends StatefulWidget {

  final Function cancelLoading;

  const LoadingScreen({Key? key, required this.cancelLoading}) : super(key: key);

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(duration: const Duration(milliseconds: 750), vsync: this);
    controller.addStatusListener(statusListener);
    controller.forward();
  }

  statusListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      controller.value = 0.0;
      controller.forward();
    }
  }

  @override
  void dispose() {
    controller.removeStatusListener(statusListener);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: (){
          widget.cancelLoading();
        },
        child: Center(
            child: Container(
              child: Center(
                child: AnimatedBuilder(
                    animation: controller.view,
                    builder: (context, snapshot) {
                      return ClipPath(
                        clipper: MyClipper(),
                        child: Container(
                          width: LocalData.deviceWidth * 0.35,
                          height: LocalData.deviceWidth * 0.35,
                          color: LocalData.myTheme.loadingBackground,
                          child: CustomPaint(
                            painter: MyCustomPainter(controller.value),
                          ),
                        ),
                      );
                    }),
              ),
            )),
      ),
    );
  }
}

class MyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double w = size.width;
    double h = size.height;

    Path path = Path();
    path.moveTo(w/2, 0);
    path.lineTo(w, h/2);
    path.lineTo(w/2, h);
    path.lineTo(0, h/2);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper oldClipper) {
    return false;
  }
}

class MyCustomPainter extends CustomPainter {
  final double percentage;

  MyCustomPainter(this.percentage);
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = LocalData.myTheme.loadingForeground
      ..style = PaintingStyle.fill;

    Rect rect = Rect.fromLTWH(0, 0, size.width, size.height * percentage);

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}