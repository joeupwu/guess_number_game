import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum Player { human, computer }
enum WinState { unknown, win, wrongHint }

class NumHint {
  String strNumber = '';
  List<int> hintVal = [-1, -1];

  factory NumHint({strNumber = '', List<int> hintVal = const [-1, -1]}) {
    return NumHint._internal(strNumber, List<int>.from(hintVal));
  }

  factory NumHint.from(NumHint numHint) {
    return NumHint._internal(
        numHint.strNumber, List<int>.from(numHint.hintVal));
  }
  String get strHint =>
      (hintVal[0] < 0 ? '?' : hintVal[0].toString()) +
      'A' +
      (hintVal[1] < 0 ? '?' : hintVal[1].toString()) +
      'B';

  NumHint._internal(this.strNumber, this.hintVal);

  void reset() {
    this.strNumber = '';
    this.hintVal = [-1, -1];
  }
}

abstract class GuessNumber {
  final int numLen;
  late final int maxNumber;
  final Player player;
  GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();
  WinState _winState = WinState.unknown;
  String strMyNumber = ''; // the number in my mind

  var _numHint = NumHint(); // my guessed number and corresponding hint
  List<NumHint> numHintList = List<NumHint>.empty(growable: true);

  GuessNumber(this.numLen, this.player) {
    assert(numLen <= 8);
    int val = 9;
    for (int i = 0; i < numLen - 1; i++) {
      val = val * 10 + ((val % 10) - 1);
    }
    maxNumber = val + 1;
    reset();
  }

  void reset() {
    for (int i = 0; i < numHintList.length; i++) {
      listKey.currentState!.removeItem(0,
          (BuildContext context, Animation<double> animation) {
        return Container();
      });
    }
    numHintList.clear();
    _numHint.reset();
    _winState = WinState.unknown;
    if (player == Player.computer) {
      strMyNumber = _genRandGuessNumber(numLen);
      _numHint.strNumber = _genRandGuessNumber(numLen);
      debugPrint("Computer number = $strMyNumber");
    }
  }

  // abstract methods
  void onBackspace();
  bool onSubmit(String oppoNumber);
  void onInput(String val);
  void prepareNext();

  String get strGuessNumber => _numHint.strNumber;
  String get strHint => _numHint.strHint;
  int get number =>
      _numHint.strNumber == '' ? 0 : int.parse(_numHint.strNumber);
  WinState get winState => _winState;

  String _int2String(int val) {
    String strVal = val.toString();

    strVal = '0' * (numLen - strVal.length) + strVal;
    return strVal;
  }

  // generate random non-repeated number with length = len
  String _genRandGuessNumber(int len) {
    var rng = new Random();
    int val = rng.nextInt(maxNumber);

    while (_isRepeatedNumber(val)) {
      val = rng.nextInt(maxNumber);
    }
    return _int2String(val);
  }

  // check if input is repeated number
  bool _isRepeatedNumber(int val) {
    String strNum = _int2String(val);

    for (int i = 1; i < strNum.length; i++) {
      String curStr = strNum.substring(i - 1, i);
      if (strNum.substring(i, strNum.length).indexOf(curStr) >= 0) return true;
    }
    return false;
  }

  // calculate hint (xAxB) according to guess number
  List<int> _calcHint(String correctNum, String guessNum) {
    int len = correctNum.length;
    List<int> result = List<int>.filled(2, 0, growable: false);

    if (len != guessNum.length) return result;

    // check position A count
    for (int i = 0; i < len; i++) {
      if (correctNum.substring(i, i + 1) == guessNum.substring(i, i + 1)) {
        result[0]++;
      }
      for (int j = 0; j < len; j++) {
        if (i != j &&
            guessNum.substring(i, i + 1) == correctNum.substring(j, j + 1)) {
          result[1]++;
        }
      }
    }
    return result;
  }

  // calculate number according to hint
  String _calcNumber() {
    // guess in sequential
    for (int i = 0; i < maxNumber; i++) {
      if (_isRepeatedNumber(i)) continue;
      String strCorrNumber = _int2String(i);
      int j = 0;
      for (j = 0; j < numHintList.length; j++) {
        List<int> hint = _calcHint(strCorrNumber, numHintList[j].strNumber);
        if (hint[0] != numHintList[j].hintVal[0] ||
            hint[1] != numHintList[j].hintVal[1]) {
          break;
        }
      }
      if (j == numHintList.length) // all matches
      {
        return strCorrNumber;
      }
    }
    return _int2String(0);
  }
}

class HumanGuessNumber extends GuessNumber {
  HumanGuessNumber(numLen, player) : super(numLen, player);

  void onBackspace() {
    if (_numHint.strNumber.length <= 0) return;
    _numHint.strNumber =
        _numHint.strNumber.substring(0, _numHint.strNumber.length - 1);
  }

  bool onSubmit(String oppoNumber) {
    if (strGuessNumber.length != numLen) return false;
    _numHint.hintVal = _calcHint(oppoNumber, strGuessNumber);
    numHintList.insert(0, NumHint.from(_numHint));
    listKey.currentState!.insertItem(0);
    if (_numHint.hintVal[0] == numLen) _winState = WinState.win;

    return true;
  }

  void prepareNext() {
    _numHint.reset();
  }

  void onInput(String val) {
    if (strGuessNumber.length >= numLen) return; // limit to numLen
    if (strGuessNumber.indexOf(val) >= 0) return; // can not repeat
    _numHint.strNumber = strGuessNumber + val;
  }
}

class ComputerGuessNumber extends GuessNumber {
  ComputerGuessNumber(numLen, player) : super(numLen, player);

  void onBackspace() {
    if (_numHint.hintVal[1] != -1) {
      _numHint.hintVal[1] = -1;
    } else if (_numHint.hintVal[0] != -1) {
      _numHint.hintVal[0] = -1;
    }
  }

  bool onSubmit(String oppoNumber) {
    if (_numHint.hintVal[1] == -1) return false;
    numHintList.insert(0, NumHint.from(_numHint));
    listKey.currentState!.insertItem(0);
    if (_numHint.hintVal[0] == numLen) _winState = WinState.win;

    if (_calcNumber() == '0000') _winState = WinState.wrongHint;

    return true;
  }

  void prepareNext() {
    // reset numHint according to new hint
    _numHint.reset();
    _numHint.strNumber = _calcNumber();

    if (_numHint.strNumber == '0000') {
      _winState = WinState.wrongHint;
    }
  }

  void onInput(String val) {
    int iVal = int.parse(val);

    if (iVal < 0 || iVal > numLen) return;

    if (_numHint.hintVal[0] == -1) {
      _numHint.hintVal[0] = iVal;
    } else if (_numHint.hintVal[1] == -1) {
      if (iVal + _numHint.hintVal[0] > numLen) return;
      _numHint.hintVal[1] = iVal;
    }
  }
}
