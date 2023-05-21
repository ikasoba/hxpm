package hxpm;

function ask(prompt: String, required: Bool = false, ?defaultValue: Null<String>){
  Sys.print(prompt + (defaultValue != null ? "[" + defaultValue + "]: " : "[]: "));
  var ans = Sys.stdin().readLine();
  if (ans == "") {
    if (required){
      Sys.print("Please enter something.");
      return ask(prompt);
    }
    return defaultValue;
  }
  return ans;
}

function choice(prompt: String, values: Array<String>){
  Sys.println(
    prompt + "\n  - "
    + values.join("\n  - ")
  );
  Sys.print(": ");
  var ans = Sys.stdin().readLine();
  if (ans == "") {
    return choice(prompt, values);
  }else if (values.indexOf(ans) < 0) {
    return choice(prompt, values);
  }
  return ans;
}