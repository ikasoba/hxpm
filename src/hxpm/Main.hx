package hxpm;

import sys.io.Process;
import haxe.DynamicAccess;
import haxe.io.Path;
import haxe.Json;
import sys.io.File;
import sys.FileSystem;
import hxpm.Question.ask;

var help = (
    "Usage:\n"
  + "  hxpm init [<dir>]                   -  initialize project\n"
  + "  hxpm install <package> [<version>]  -  install package\n"
  + "  hxpm remove <package>               -  uninstall package\n"
  + "  hxpm install-dep                    -  install project dependencies"
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

  if (args.get("subcommand") == "init"){
    init(args.get("dir"));
  }else if (args.get("subcommand") == "install"){
    install(args.get("pkg"), args.get("version"));
  }else if (args.get("subcommand") == "remove"){
    remove(args.get("pkg"));
  }else if (args.get("subcommand") == "install-dep"){
    installDep();
  }
}

/** プロジェクトを初期化する */
function init(dir: String) {
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

  var branch = ask("git branch name", false);

  Sys.command("git", ["init"].concat(branch != null ? ["-b", branch] : []));

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

  Sys.setCwd(prevPath);
}

/** パッケージをインストールする */
function install(pkg: String, ?version: Null<String>){
  var packageVersion = "";
  if (version == null){
    var proc = new Process("haxelib", ["info", pkg]);
    var code = proc.exitCode();
    if (code != 0){
      Sys.println(proc.stdout.readAll().toString());
      Sys.exit(1);
      return;
    }
    var regex = ~/Version: (.+)/;
    regex.match(proc.stdout.readAll().toString());
    packageVersion = regex.matched(1);
  }else{
    packageVersion = version;
  }
  if (Sys.command("haxelib", ["install", pkg, packageVersion]) != 0){
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
  dependencies.set(pkg, packageVersion);

  File.saveContent("haxelib.json", Json.stringify(haxelib, null, "  "));
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