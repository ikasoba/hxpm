package hxpm.config;

import hxpm.Question.ask;

function installRuntimeLib (interp: hscript.Interp){
  interp.variables.set(
    "ask", Reflect.makeVarArgs((args) -> {
      return ask(args.shift());
    })
  );

  interp.variables.set("Array", Array);
  interp.variables.set("Sys", Sys);
  interp.variables.set("sys", {
    "FileSystem": sys.FileSystem,
    "Http": sys.Http,
    "io": {
      "File": sys.io.File
    }
  });
  interp.variables.set("haxe", {
    "Json": haxe.Json
  });
}

function execute(src: String): { interp: hscript.Interp, value: Dynamic } {
  var parser = new hscript.Parser();
  var interp = new hscript.Interp();
  installRuntimeLib(interp);

  return {
    interp: interp,
    value: interp.execute(parser.parseString(src))
  };
}