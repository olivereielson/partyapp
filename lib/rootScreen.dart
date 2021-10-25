import 'dart:async';

import 'package:bouncer/User.dart';
import 'package:bouncer/UserScan.dart';
import 'package:bouncer/login.dart';
import 'package:bouncer/search.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links/uni_links.dart';



bool _initialUriIsHandled = false;

class rootScreen extends StatefulWidget {
  final FirebaseAnalytics analytics;

  rootScreen({required this.analytics});

  @override
  State<rootScreen> createState() => _rootScreenState();
}

class _rootScreenState extends State<rootScreen> {
  late Future<void> _initializeFlutterFireFuture;
  FirebasePerformance _performance = FirebasePerformance.instance;

  StreamSubscription? _sub;
  Uri? _initialUri;
  Uri? _latestUri;
  Object? _err;

  PersistentTabController _controller = PersistentTabController(
    initialIndex: 0,
  );

  savecode(String id) async {


    SharedPreferences prefs = await SharedPreferences.getInstance();


    if (prefs.containsKey("wallet")) {
      List<String>? codes = prefs.getStringList("wallet");
      codes!.add(id);
      prefs.setStringList("wallet", codes);
    } else {
      prefs.setStringList("wallet", [id]);
    }

  }

  void _handleIncomingLinks() {
    if (!kIsWeb) {
      // It will handle app links while the app is already started - be it in
      // the foreground or in the background.
      _sub = uriLinkStream.listen((Uri? uri) {
        if (!mounted) return;
        print('got initial uri: ${uri.toString().replaceAll('partylabs://partylabsinvitecodelink.com/', "")}');

        savecode(uri.toString().replaceAll('partylabs://partylabsinvitecodelink.com/', ""));
        _controller.jumpToTab(0);

        setState(() {
          _latestUri = uri;
          _err = null;
        });
      }, onError: (Object err) {
        if (!mounted) return;
        print('got err: $err');
        setState(() {
          _latestUri = null;
          if (err is FormatException) {
            _err = err;
          } else {
            _err = null;
          }
        });
      });
    }
  }

  Future<void> _handleInitialUri() async {
    // In this example app this is an almost useless guard, but it is here to
    // show we are not going to call getInitialUri multiple times, even if this
    // was a weidget that will be disposed of (ex. a navigation route change).
    if (!_initialUriIsHandled) {
      _initialUriIsHandled = true;
      //_showSnackBar('_handleInitialUri called');
      try {
        final uri = await getInitialUri();
        if (uri == null) {
          print('no initial uri');
        } else {
          print('got initial uri: ${uri.toString().replaceAll('partylabs://partylabsinvitecodelink.com/', "")}');
          savecode(uri.toString().replaceAll('partylabs://partylabsinvitecodelink.com/', ""));
          _controller.jumpToTab(0);

        }
        if (!mounted) return;
        setState(() => _initialUri = uri);
      } on PlatformException {
        // Platform messages may fail but we ignore the exception
        print('falied to get initial uri');
      } on FormatException catch (err) {
        if (!mounted) return;
        print('malformed initial uri');
        setState(() => _err = err);
      }
    }
  }

  List<Widget> _buildScreens() {
    return [
      Userpage(analytics: widget.analytics),
      LoginPage(analytics: widget.analytics),
      partySearch()
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
        icon: Icon(
          CupertinoIcons.profile_circled,
        ),
        title: ("Host"),
        activeColorPrimary: CupertinoColors.white,
        inactiveColorPrimary: CupertinoColors.systemGrey,
      ),

      PersistentBottomNavBarItem(
        icon: Icon(
          CupertinoIcons.search,
        ),
        title: ("Search"),
        activeColorPrimary: CupertinoColors.white,
        inactiveColorPrimary: CupertinoColors.systemGrey,
      ),


    ];
  }

  @override
  Widget build(BuildContext context) {


    return FutureBuilder(
      future: _initializeFlutterFireFuture,
        builder: (context, snapshot) {


        if(snapshot.connectionState==ConnectionState.done){

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
                handleAndroidBackButtonPress: true,
                // Default is true.
                resizeToAvoidBottomInset: false,
                // This needs to be true if you want to move up the screen when keyboard appears. Default is true.
                stateManagement: true,
                // Default is true.

                hideNavigationBarWhenKeyboardShows: true,
                // Recommended to set 'resizeToAvoidBottomInset' as true while using this argument. Default is true.
                decoration: NavBarDecoration(
                    borderRadius: BorderRadius.only(
                        topRight: Radius.circular(_controller.index == 0 ? 20.0 : 0),
                        topLeft: Radius.circular(_controller.index == 0 ? 20.0 : 0)),
                    colorBehindNavBar: Colors.transparent,
                    adjustScreenBottomPaddingOnCurve: true),
                popAllScreensOnTapOfSelectedTab: true,
                popActionScreens: PopActionScreensType.all,
                itemAnimationProperties: ItemAnimationProperties(
                  // Navigation Bar's items animation properties.
                  duration: Duration(milliseconds: 200),
                  curve: Curves.ease,
                ),
                screenTransitionAnimation: ScreenTransitionAnimation(
                  // Screen transition animation on change of selected tab.
                  animateTabTransition: false,
                  curve: Curves.ease,
                  duration: Duration(milliseconds: 200),
                ),


                navBarStyle: NavBarStyle
                    .style8, // Choose the nav bar style with this property.
              ),

            ),
          );


        }


        if(snapshot.connectionState==ConnectionState.none) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );

        }




          return Text("Loading");

        }


    );



  }


  Future<void> _initializeFlutterFire() async {
    // Wait for Firebase to initialize

    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);


    // Pass all uncaught errors to Crashlytics.
    Function originalOnError = FlutterError.onError as Function;
    FlutterError.onError = (FlutterErrorDetails errorDetails) async {
      await FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
      // Forward to original handler.
      originalOnError(errorDetails);
    };

  }

  Future<void> _togglePerformanceCollection() async {
    await _performance.setPerformanceCollectionEnabled(true);
    final bool isEnabled = await _performance.isPerformanceCollectionEnabled();

    print("performance is turned on:$isEnabled");

  }



  @override
  void initState() {
    _controller.addListener(() {
      setState(() {});
    });

    super.initState();
    _initializeFlutterFireFuture = _initializeFlutterFire();
    _togglePerformanceCollection();
    _handleIncomingLinks();
    _handleInitialUri();

  }
  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}


