class CMHelpers {
  static int getStringIndex(String input) {
    final hash = input.codeUnits.fold(0, (prev, char) => prev + char);
    return hash % 10;
  }
}
