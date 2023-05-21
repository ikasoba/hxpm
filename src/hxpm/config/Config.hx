package hxpm.config;

import hxpm.config.Script.execute;
import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;

function loadConfig() {
  var path = Path.join([Path.directory(Sys.programPath()), ".config.hx"]);
  if (!FileSystem.exists(path)){
    File.saveContent(
      path,
        "function postInit() {\n"
      + "  var branch = ask(\"git branch name\");\n"
      + "  if (branch == null){\n"
      + "    Sys.command(\"git\", [\"init\"]);\n"
      + "  }else{\n"
      + "    Sys.command(\"git\", [\"init\", \"-b\", branch]);\n"
      + "  }\n"
      + "}"
    );
  }
  return execute(File.getContent(path));
}