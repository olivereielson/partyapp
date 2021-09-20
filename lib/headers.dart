import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MyDynamicHeader extends SliverPersistentHeaderDelegate {

  MyDynamicHeader(this.button);

  Widget button;

  String text1="Saved";
  String text2="Passes";
  int index=0;

  Tween pos_x = Tween<double>(begin: 20, end: 20);

  Tween pos_y = Tween<double>(begin: 30, end: 20);

  Tween pos_x2 = Tween<double>(begin: 20, end: 110);
  Tween pos_x2_g = Tween<double>(begin: 20, end: 140);

  Tween pos_y2 = Tween<double>(begin: 80, end: 20);

  Tween Font = Tween<double>(begin: 50, end: 25);
  Tween Font2 = Tween<double>(begin: 40, end: 25);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return LayoutBuilder(
        
        
        builder: (context, constraints) {
      final double percentage = 1 - (constraints.maxHeight - minExtent) / (maxExtent - minExtent);

      final double posx = pos_x.lerp(percentage)as double;
      final double posy = pos_y.lerp(percentage)as double;
      final double posx2 = pos_x2.lerp(percentage)as double;
      final double posy2 = pos_y2.lerp(percentage)as double;
      final double font = Font.lerp(percentage) as double;
      final double font2 = Font2.lerp(percentage) as double;

      if (++index > Colors.primaries.length - 1) index = 0;

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20.0),bottomRight: Radius.circular(20.0),topLeft: Radius.circular(40.0),topRight: Radius.circular(40.0)),
          color: Color.fromRGBO(48, 48, 48, 1),
          border: Border.all(color: Colors.transparent,width: 4),

        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Positioned(
                  left: posx,
                  top: posy,
                  child: Text(
                    text1,
                    style: TextStyle(color: Colors.white, fontSize: font, fontWeight: FontWeight.bold),
                  )),
              Positioned(left: posx2, top: posy2, child: Text(text2, style: TextStyle(color: percentage == 1 ? Colors.white : Colors.white70, fontSize: font2, fontWeight: FontWeight.bold)))
           , Positioned(

                right: 10,
                  top: 10,

                  child: button)
            ],
          ),
        ),
      );
    });
  }

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate _) => true;

  @override
  double get maxExtent => 200.0;

  @override
  double get minExtent => 130.0;
}
class MyDynamicHeader2 extends SliverPersistentHeaderDelegate {

  MyDynamicHeader2(this.button,this.nums);

  Widget button;
  double nums;

  String text1="Saved";
  String text2="Passes";
  int index=0;


  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return LayoutBuilder(builder: (context, constraints) {
      final double percentage = 1 - (constraints.maxHeight - minExtent) / (maxExtent - minExtent);


      if (++index > Colors.primaries.length - 1) index = 0;

      return Container(
        decoration: BoxDecoration(
          
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
                child: SafeArea(child: button)),
          ],
        ),
      );
    });
  }

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate _) => true;

  @override
  double get maxExtent =>nums;

  @override
  double get minExtent => 1.0;
}
