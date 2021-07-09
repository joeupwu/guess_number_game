// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'number_hint.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$NumberHint on _NumberHintBase, Store {
  final _$numAtom = Atom(name: '_NumberHintBase.num');

  @override
  int get num {
    _$numAtom.reportRead();
    return super.num;
  }

  @override
  set num(int value) {
    _$numAtom.reportWrite(value, super.num, () {
      super.num = value;
    });
  }

  @override
  String toString() {
    return '''
num: ${num}
    ''';
  }
}
