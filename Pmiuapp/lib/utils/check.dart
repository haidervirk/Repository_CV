bool Check(String input, Map<String, List> dataSet){
  final String inputFirstCapital = "${input[0].toUpperCase()}${input.substring(1).toLowerCase()}";

  if(dataSet[inputFirstCapital] == null)
    {
      return false;
    }
  else
    {
      return true;
    }

}
