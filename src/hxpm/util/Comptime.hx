package hxpm.util;

import haxe.macro.Expr.ExprOf;
import haxe.Json;
import haxe.macro.Context;
import sys.io.File;

macro function readJsonFromFile(path: String): ExprOf<Dynamic> {
  try {
    var raw = File.getContent(path);
    var json = Json.parse(raw);
    return Context.makeExpr(json, Context.currentPos());
  }catch(err){
    var cwd = Sys.getCwd();
    return Context.error('failed load json file ${path}\n${err}\n${cwd}', Context.currentPos());
  }
}