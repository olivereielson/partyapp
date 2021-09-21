import 'package:bouncer/User.dart';
import 'package:bouncer/UserScan.dart';
import 'package:bouncer/login.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';

class rootScreen extends StatefulWidget {

  final FirebaseAnalytics analytics;

  rootScreen({required this.analytics});


  @override
  State<rootScreen> createState() => _rootScreenState();
}

class _rootScreenState extends State<rootScreen> {

  PersistentTabController _controller = PersistentTabController(initialIndex: 0,);




  List<Widget> _buildScreens() {
    return [
      Userpage(analytics: widget.analytics),

      LoginPage(analytics: widget.analytics),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: Icon(CupertinoIcons.ticket),
        title: ("Passes"),
        activeColorPrimary: CupertinoColors.white,
          inactiveColorPrimary: CupertinoColors.systemGrey,

      ),
      PersistentBottomNavBarItem(
        icon: Icon(CupertinoIcons.profile_circled,),
        title: ("Host"),
        activeColorPrimary: CupertinoColors.white,

        inactiveColorPrimary: CupertinoColors.systemGrey,


      ),
    ];
  }

  @override
  Widget build(BuildContext context) {






    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(

        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),


        child: PersistentTabView(
          context,
          controller: _controller,
          screens: _buildScreens(),
          items: _navBarsItems(),

          confineInSafeArea: true,
          backgroundColor: Color.fromRGBO(60, 60, 60, 1),
          //backgroundColor: _controller.index==1?Color.fromRGBO(58, 58, 58, 1):Color.fromRGBO(47, 47, 47, 0), // Default is Colors.white.
          handleAndroidBackButtonPress: true, // Default is true.
          resizeToAvoidBottomInset: false, // This needs to be true if you want to move up the screen when keyboard appears. Default is true.
          stateManagement: true, // Default is true.

          hideNavigationBarWhenKeyboardShows: true, // Recommended to set 'resizeToAvoidBottomInset' as true while using this argument. Default is true.
          decoration: NavBarDecoration(
            borderRadius: BorderRadius.only(topRight: Radius.circular(_controller.index==0?20.0:0),topLeft: Radius.circular(_controller.index==0?20.0:0)),
            colorBehindNavBar: Colors.transparent,
            adjustScreenBottomPaddingOnCurve: true
          ),
          popAllScreensOnTapOfSelectedTab: true,
          popActionScreens: PopActionScreensType.all,
          itemAnimationProperties: ItemAnimationProperties( // Navigation Bar's items animation properties.
            duration: Duration(milliseconds: 200),
            curve: Curves.ease,
          ),
          screenTransitionAnimation: ScreenTransitionAnimation( // Screen transition animation on change of selected tab.
            animateTabTransition: false,
            curve: Curves.ease,
            duration: Duration(milliseconds: 200),
          ),

          navBarStyle: NavBarStyle.style8, // Choose the nav bar style with this property.
        ),
      ),
    );
  }
  @override
  void initState() {

    _controller.addListener(() {


      setState(() {

      });

    });

    super.initState();
  }
}
