// example: '23.430000' => '23.43'
String removeDotZero (String input){
  if (input.contains('.') && !input.contains('e-') && !input.contains('e+')){
    input = input.substring(0, RegExp(r'0+$').firstMatch(input)?.start);
    if (input[input.length-1] == '.') input = input.substring(0, input.length-1);
  }
  return input;
}