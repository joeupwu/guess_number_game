import 'package:mobx/mobx.dart';
part 'number_hint.g.dart';

class NumberHint = _NumberHintBase with _$NumberHint;

abstract class _NumberHintBase with Store {
  @observable
  int num = 0;
  int hintA = 0;
  int hintB = 0;
}
