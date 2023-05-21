# release 0.1.2

`.config.hx` is added.

The `.config.hx` is automatically created in the same directory as the executable file and can be used to execute any process at any time, such as when the project is initialized.

## Timing.

- `postInit`.

  By defining the function `postInit`, you can execute any process after initialization.

## Built-in functions in `.config.hx`.

- `ask`

  ```haxe
  (prompt: String) -> Null<String>
  ```

  Takes input from the standard input.
  If no input is given, null is returned.

## Example of `.config.hx`

```haxe
function postInit() {
  var branch = ask("git branch name");
  if (branch == null){
    Sys.command("git", ["init"]);
  }else{
    Sys.command("git", ["init", "-b", branch]);
  }
}
```
