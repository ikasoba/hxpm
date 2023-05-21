package hxpm;

enum HxmlExpr {
  Comment(content: String);
  Option(name: String, value: Null<String>);
  InvokeHxml(path: String);
}

class Hxml {
  public static function skipRegex(regex: EReg): (index: Int, src: String) -> Int {
    return (index: Int, src: String) -> {
      if (!regex.match(src.substr(index)))return index;
      index += regex.matchedPos().len;
      return index;
    }
  }

  public static function parse(src: String): Array<HxmlExpr> {
    var index = 0;
    var result = new Array<HxmlExpr>();

    while (index < src.length){
      index = skipRegex(~/^[\r\n \t]*/)(index, src);
      // オプションのパース
      if (src.charAt(index) == "-"){
        var regex = ~/^(-+[a-zA-Z-]*)[ \t]+(.*)/;
        if (!regex.match(src.substr(index))){
          index++;
          continue;
        }
        var optionName = regex.matched(1);
        var value = regex.matched(2);
        index += regex.matchedPos().len;

        result.push(HxmlExpr.Option(optionName, value));
      // コメントのパース
      }else if (src.charAt(index) == "#"){
        var start = index;
        index = skipRegex(~/^#.+/)(index, src);

        result.push(HxmlExpr.Comment(src.substr(start, index - start)));
      // hxml呼び出しのパース
      }else{
        var start = index;
        index = skipRegex(~/^.+/)(index, src);

        result.push(HxmlExpr.InvokeHxml(src.substr(start, index - start)));
      }
    }

    return result;
  }

  public static function stringify(hxml: Array<HxmlExpr>): String {
    return hxml.map(x -> {
      switch (x){
        case Comment(content):
          return "#" + content;

        case Option(name, value):
          return name + " " + value;

        case InvokeHxml(path):
          return path;
      }
      return "";
    }).join("\n");
  }
}