import 'dart:io' show Platform, exit;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:numeric_keyboard/numeric_keyboard.dart';
import 'animate_text.dart';
import 'guess_number.dart';
//import 'store/number_hint.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var materialApp = MaterialApp(
      title: 'Guess number game',
      //locale: Locale('en'), // force the locale to ...
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', ''),
        const Locale.fromSubtags(
            languageCode: 'zh',
            scriptCode: 'Hant',
            countryCode: 'TW'), // 'zh_Hant_TW'
      ],
      theme: ThemeData.light(),
      home: HomePage(),
    );
    return materialApp;
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(AppLocalizations.of(context)!.guessnumbergame)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Padding(
              padding: EdgeInsets.all(30),
              child: Text(AppLocalizations.of(context)!.rules),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GuessNumberPage()),
              ),
              child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(AppLocalizations.of(context)!.startgame)),
            ),
          ],
        ),
      ),
    );
  }
}

class GuessNumberPage extends StatefulWidget {
  const GuessNumberPage({Key? key}) : super(key: key);

  @override
  _GuessNumberPageState createState() => _GuessNumberPageState();
}

class _GuessNumberPageState extends State<GuessNumberPage> {
  static const int _numLen = 4;
  Player _turn = Player.human;

  var guessNumber = [
    HumanGuessNumber(_numLen, Player.human),
    ComputerGuessNumber(_numLen, Player.computer)
  ];

  var msgTitle = List.filled(2, "");

  @override
  void initState() {
    super.initState();
    //guessNumber[0].strOppoNumber = guessNumber[1].strNumber;
  }

  @override
  Widget build(BuildContext context) {
    msgTitle[0] = AppLocalizations.of(context)!.yourturn;
    msgTitle[1] = AppLocalizations.of(context)!.compturn;

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(AppLocalizations.of(context)!.guessnumbergame),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            AnimatedSwitcher(
                duration: Duration(milliseconds: 1000),
                child: guessPanel(_turn, key: ValueKey(_turn.index)),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return slideTransitions(child, animation,
                      vertSlide: false, childKey1: ValueKey(_turn.index));
                }),
            NumericKeyboard(
              onKeyboardTap: _onKeyboardTap,
              textColor: Colors.blue,
              rightIcon: Icon(Icons.backspace, color: Colors.red),
              rightButtonFn: () => setState(() {
                guessNumber[_turn.index].onBackspace();
              }),
              leftIcon: Icon(Icons.check),
              leftButtonFn: () async {
                bool isReady = false;
                setState(() {
                  isReady = guessNumber[_turn.index]
                      .onSubmit(guessNumber[1 - _turn.index].strMyNumber);
                });
                if (!isReady) return;
                if (guessNumber[_turn.index].winState == WinState.unknown) {
                  await Future.delayed(Duration(seconds: 1), () {
                    setState(() {
                      guessNumber[_turn.index].prepareNext();
                      _turn = Player.values[1 - _turn.index];
                    });
                  });
                  return;
                }
                String msgTitle = '', msgContent = '';
                bool result = false;
                if (guessNumber[_turn.index].winState == WinState.wrongHint) {
                  msgTitle = AppLocalizations.of(context)!.warning;
                  msgContent = AppLocalizations.of(context)!.incorrecthint;
                } else {
                  if (_turn == Player.computer) {
                    msgTitle = AppLocalizations.of(context)!.youloss;
                    msgContent = AppLocalizations.of(context)!.playagain;
                  } else {
                    msgTitle = AppLocalizations.of(context)!.youwin;
                    msgContent = AppLocalizations.of(context)!.playagain;
                  }
                }
                result = (await _showDialog(msgTitle, msgContent))!;
                if (result) {
                  setState(() {
                    guessNumber[0].reset();
                    guessNumber[1].reset();
                    _turn = Player.human;
                  });
                } else {
                  if (kIsWeb) {
                    Navigator.pop(context);
                  } else if (Platform.isWindows || Platform.isLinux) {
                    exit(0);
                  } else {
                    SystemNavigator.pop();
                  }
                }
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.yourhistory),
                    numHintListView(
                      guessNumber[Player.human.index].numHintList,
                      guessNumber[Player.human.index].listKey,
                    ),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.comphistory),
                    numHintListView(
                      guessNumber[Player.computer.index].numHintList,
                      guessNumber[Player.computer.index].listKey,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget slideTransitions(Widget child, Animation<double> animation,
      {bool vertSlide = false, Key? childKey1}) {
    Offset offIn = Offset(1.0, 0.0);
    Offset offOut = Offset(-1.0, 0.0);

    if (vertSlide) {
      offIn = Offset(0.0, 1.0);
      offOut = Offset(0.0, -1.0);
    }
    final inAnimation =
        Tween<Offset>(begin: offIn, end: Offset(0.0, 0.0)).animate(animation);
    final outAnimation =
        Tween<Offset>(begin: offOut, end: Offset(0.0, 0.0)).animate(animation);

    if (child.key == childKey1) {
      return ClipRect(
        child: SlideTransition(
          position: inAnimation,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: child,
          ),
        ),
      );
    } else {
      return ClipRect(
        child: SlideTransition(
          position: outAnimation,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: child,
          ),
        ),
      );
    }
  }

  // Widget animatedText(String data,
  //     {Duration duration: const Duration(milliseconds: 400), Color? color}) {
  //   return AnimatedSwitcher(
  //     duration: duration,
  //     child: Text(
  //       data,
  //       key: ValueKey(data),
  //       style:
  //           TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: color),
  //     ),
  //     transitionBuilder: (Widget child, Animation<double> animation) {
  //       return slideTransitions(child, animation,
  //           vertSlide: true, childKey1: ValueKey(data));
  //     },
  //   );
  // }

  Widget guessPanel(Player player, {Key? key}) {
    return Column(key: key, children: <Widget>[
      Padding(
        padding: EdgeInsets.all(10),
        child: Text(msgTitle[player.index], style: TextStyle(fontSize: 24)),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          AnimatedFlipText(
            value: (_formatText(guessNumber[player.index].strGuessNumber)),
            duration: Duration(milliseconds: 300),
            size: 36,
          ),
          AnimatedFlipText(
            value: (guessNumber[player.index].strHint),
            duration: Duration(milliseconds: 300),
            size: 36,
          ),
        ],
      ),
    ]);
  }

  Widget numHintListItem(int inx, NumHint numHint) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(inx.toString()),
            Text(
              numHint.strNumber,
              style: TextStyle(color: Colors.blue, fontSize: 20),
            ),
            Text(
              numHint.strHint,
              style: TextStyle(color: Colors.red, fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget numHintListView(List<NumHint> nhList, listKey) {
    return Container(
      width: 200,
      height: 200,

      // child: ListView.builder(
      //   shrinkWrap: true,
      //   itemCount: nhList.length,
      //   itemBuilder: (context, index) {
      //     return numHintListItem(index + 1, nhList[index]);
      //   },
      // ),

      child: AnimatedList(
        key: listKey,
        initialItemCount: nhList.length,
        itemBuilder:
            (BuildContext context, int index, Animation<double> animation) {
          return SizeTransition(
            sizeFactor: animation,
            child: numHintListItem(index + 1, nhList[index]),
          );
        },
      ),
    );
  }

  _onKeyboardTap(String value) {
    setState(() {
      guessNumber[_turn.index].onInput(value);
    });
  }

  String _formatText(String value) {
    String newValue = '';
    int len = _numLen - value.length;

    if (len >= 0) {
      newValue = value + '-' * len;
    }
    return newValue;
  }

  Future<bool?> _showDialog(String title, String content) {
    return showDialog<bool>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) => AlertDialog(
              title: Text(title),
              content: Text(content),
              actions: <Widget>[
                ElevatedButton(
                  child: Text(AppLocalizations.of(context)!.yes),
                  onPressed: () => Navigator.pop(context, true),
                ),
                ElevatedButton(
                  child: Text(AppLocalizations.of(context)!.no),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ));
  }
}
// -----------------------------------------------------------------------------
