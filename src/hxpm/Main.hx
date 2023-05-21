package hxpm;

import hxpm.util.Comptime.readJsonFromFile;
import haxe.Constraints.Function;
import hxpm.config.Config.loadConfig;
import hxpm.Hxml.HxmlExpr;
import hxpm.Util.startsWith;
import sys.io.Process;
import haxe.DynamicAccess;
import haxe.io.Path;
import haxe.Json;
import sys.io.File;
import sys.FileSystem;
import hxpm.Question.ask;

var help = (
    "Usage:\n"
  + "  hxpm init [<dir>]                        -  initialize project.\n"
  + "  hxpm install [-L] <package> [<version>]  -  install package.\n"
  + "                                              The -L option can be used to add libraries to build.hxml.\n"
  + "  hxpm remove <package>                    -  uninstall package.\n"
  + "  hxpm install-dep                         -  install project dependencies.\n"
  + "  hxpm version                             -  show hxpm version."
);

function main(){
  var parser = new Argparse();
  parser.setSubCommand(
    "init",
    new Argparse().addPositional("dir", true)
  );

  parser.setSubCommand(
    "install",
    new Argparse()
      .addPositional("pkg", true)
      .addPositional("version", false)
      .addSwitch("L", "true", "false")
  );

  parser.setSubCommand(
    "remove",
    new Argparse()
      .addPositional("pkg", true)
  );

  parser.setSubCommand(
    "install-dep",
    new Argparse()
  );

  parser.setSubCommand(
    "version",
    new Argparse()
  );

  var result = parser.parse(Sys.args());
  var args: Map<String, String>;
  switch (result){
    case Err(value): {
      Sys.println("Error: " + value + "\n");
      Sys.println(help);
      Sys.exit(1);
      return;
    };

    case Ok(value): {
      args = value;
    };
  }

  switch (args.get("subcommand")){
    case "init": {
      init(args.get("dir"));
    };

    case "install": {
      install(args.get("pkg"), args.get("version"), args.get("L") == "true");
    };

    case "remove": {
      remove(args.get("pkg"));
    };

    case "install-dep": {
      installDep();
    };

    case "version": {
      var haxelib = readJsonFromFile("haxelib.json");
      Sys.println(haxelib.version);
    };
  }
}

/** プロジェクトを初期化する */
function init(dir: String) {

  var config = loadConfig();

  var prevPath = Sys.getCwd();
  if (!FileSystem.exists(dir)){
    FileSystem.createDirectory(dir);
  }

  Sys.setCwd(dir);

  var projectName = ask("project name", Path.withoutDirectory(Path.removeTrailingSlashes(dir)));
  var projectIdent = ~/-/g.replace(projectName, "_");

  var project = {
    name: projectName,
    version: ask("project version", "1.0.0"),
    license: ask("project license", "Public"),
    description: ask("project description", false, ""),
    classPath: "src/",
    main: projectIdent + ".Main"
  }

  Sys.command("haxelib", ["newrepo"]);

  File.saveContent("haxelib.json", Json.stringify(project, null, "  "));
  File.saveContent(
    ".gitignore",
      ".haxelib/\n"
    + "haxe-output/"
  );

  File.saveContent(
    "build.hxml",
      "--class-path " + project.classPath + "\n"
    + "--main " + project.main + "\n"
    + "--cpp haxe-output/"
  );

  File.saveContent(
    "run.hxml",
      "--class-path " + project.classPath + "\n"
    + "--run " + project.main
  );

  FileSystem.createDirectory("./src/");
  FileSystem.createDirectory("./src/" + projectIdent);

  File.saveContent(
    "src/" + projectIdent + "/Main.hx",
      "package " + projectIdent + ";\n"
    + "\n"
    + "function main(){\n"
    + "  Sys.println(\"Hello, world!\");\n"
    + "}"
  );

  install("hxcpp");

  if (config.interp.variables.exists("postInit")){
    var postInit = config.interp.variables.get("postInit");
    postInit();
  }

  Sys.setCwd(prevPath);
}

/** パッケージをインストールする */
function install(pkg: String, ?version: Null<String>, addLib: Bool = false){
  if (Sys.command("haxelib", ["install", pkg].concat(version != null ? [version] : [])) != 0){
    Sys.exit(1);
    return;
  }
  var haxelib: DynamicAccess<Dynamic> = {};
  if (FileSystem.exists("haxelib.json")){
    haxelib = Json.parse(File.getContent("haxelib.json"));
  }

  if (!haxelib.exists("dependencies")){
    haxelib.set("dependencies", {});
  }

  var packageVersion = version != null ? version : File.getContent(".haxelib/" + pkg + "/.current");

  var dependencies: DynamicAccess<Dynamic> = haxelib.get("dependencies");
  dependencies.set(pkg, packageVersion);

  File.saveContent("haxelib.json", Json.stringify(haxelib, null, "  "));

  if (addLib){
    if (FileSystem.exists("build.hxml")){
      var hxml = Hxml.parse(File.getContent("build.hxml"));
      var i = 0;

      while (i < hxml.length){
        switch (hxml[i]){
          case Option(name, value): {
            if (name == "-L" && startsWith(value, pkg)){
              hxml.splice(i, 1);
            }
          }

          default: {};
        }
        i++;
      }

      hxml.push(HxmlExpr.Option("-L", pkg + ":" + packageVersion));
      File.saveContent("build.hxml", Hxml.stringify(hxml));
    }
  }
}

/** パッケージをアンインストールする */
function remove(pkg: String){
  if (Sys.command("haxelib", ["remove", pkg]) != 0){
    Sys.exit(1);
    return;
  }
  var haxelib: DynamicAccess<Dynamic> = {};
  if (FileSystem.exists("haxelib.json")){
    haxelib = Json.parse(File.getContent("haxelib.json"));
  }

  if (!haxelib.exists("dependencies")){
    haxelib.set("dependencies", {});
  }

  var dependencies: DynamicAccess<Dynamic> = haxelib.get("dependencies");
  dependencies.remove(pkg);

  File.saveContent("haxelib.json", Json.stringify(haxelib, null, "  "));

  if (FileSystem.exists("build.hxml")){
    var hxml = Hxml.parse(File.getContent("build.hxml"));
    var i = 0;

    while (i < hxml.length){
      switch (hxml[i]){
        case Option(name, value): {
          if (name == "-L" && startsWith(value, pkg)){
            hxml.splice(i, 1);
          }
        }

        default: {};
      }
      i++;
    }

    File.saveContent("build.hxml", Hxml.stringify(hxml));
  }
}

/** プロジェクトの依存関係をインストールする */
function installDep() {
  var haxelib: DynamicAccess<Dynamic> = {};
  if (FileSystem.exists("haxelib.json")){
    haxelib = Json.parse(File.getContent("haxelib.json"));
  }

  if (!haxelib.exists("dependencies")){
    haxelib.set("dependencies", {});
  }

  var dependencies: DynamicAccess<Dynamic> = haxelib.get("dependencies");

  for (pkg => version in dependencies.keyValueIterator()){
    if (Sys.command("haxelib", ["install", pkg, version]) != 0){
      Sys.exit(1);
      return;
    }
  }
}