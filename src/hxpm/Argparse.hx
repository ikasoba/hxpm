package hxpm;

enum ArgParser {
  // --<name>=<value>
  Flag(name: String, required: Bool);

  // --<name>
  Switch(name: String, value: String, defaultValue: Null<String>);
}

enum ParserResult<T, E> {
  Ok(value: T);
  Err(value: E);
}

typedef Positional = {
  name: String,
  required: Bool,
  defaultValue: Null<String>
};

class Argparse {
  public var parsers = new Array<ArgParser>();
  public var positionalArgs = new Array<Positional>();
  public var subCommands = new Map<String, Argparse>();

  public function new() {}

  public function setSubCommand(name: String, parser: Argparse) {
    this.subCommands.set(name, parser);
    return this;
  }

  public function addFlag(name: String, required: Bool = false) {
    this.parsers.push(ArgParser.Flag(name, required));
    return this;
  }

  public function addSwitch(name: String, value: String, ?defaultValue: Null<String>) {
    this.parsers.push(ArgParser.Switch(name, value, defaultValue));
    return this;
  }

  public function addPositional(name: String, required: Bool = true, ?defaultValue: Null<String>) {
    this.positionalArgs.push({
      name: name,
      required: required,
      defaultValue: defaultValue
    });
    return this;
  }

  public function parse(args: Array<String>, ?dest: Null<Map<String, String>>): ParserResult<Map<String, String>, String> {
    var result: Map<String, String> =
      if (dest == null){
        new Map<String, String>();
      }else{
        dest;
      };
    var index = 0;
    for (k => v in this.subCommands.keyValueIterator()){
      index = 0;
      if (args[index] == k){
        result.set("subcommand", k);
        return v.parse(args.slice(1), result);
      }
      index = 1;
    }
    if (index == 1){
      return ParserResult.Err("Invalid subcommand type.");
    }
    var positionalIndex = 0;
    for (item in args){
      if (positionalIndex < this.positionalArgs.length && item.charAt(0) != "-"){
        var positional = this.positionalArgs[positionalIndex];
        result.set(positional.name, item);
        positionalIndex++;
        continue;
      }
      for (parser in this.parsers){
        switch (parser){
          case Flag(name, _): {
            if (item == "--" + name && item.charAt(item.length - 1) == "="){
              if (index + 1 >= args.length){
                return ParserResult.Err("Invalid option.\nA value is required, but no value exists.");
              }
              result.set(name, args[index++]);
            }
          };

          case Switch(name, value, _): {
            if (item == "--" + name || item == "-" + name){
              result.set(name, value);
            }
          };
        }
      }
      index++;
    }
    for (positional in this.positionalArgs){
      if (!result.exists(positional.name)){
        if (positional.required){
          return ParserResult.Err("Argument <" + positional.name + "> was required but not specified.");
        }
        result.set(positional.name, positional.defaultValue);
      }
    }
    for (parser in this.parsers){
      switch (parser){
        case Flag(name, required): {
          if (required && !result.exists(name)){
            return ParserResult.Err("Option --" + name + " was required but not specified.");
          }
        };

        case Switch(name, _, defaultValue): {
          if (!result.exists(name)){
            result.set(name, defaultValue);
          }
        };
      }
    }
    return ParserResult.Ok(dest);
  }
}