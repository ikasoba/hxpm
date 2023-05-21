package hxpm;

function startsWith(str: String, value: String, pos: Int = 0): Bool {
  return str.substr(pos, value.length) == value;
}