# Gutter jump micro editor plugin

## Commands

The plugin provides the following commands:

 | Command       | Description of function                              |  Key  |
 | ------------- | :--------------------------------------------------- | :---: |
 | gutterUp      | Jump up if there is a gutter error message           |       |
 | gutterDown    | Jump down if there is a gutter error message         |       |
 | gutterInfo    | Buffer Log info of the gutter messages               |       |
 | '             | This can be viewed by ctl + e then type 'log'        |       |

## Custom Key Bindings

Add a file, if not already created in `~/.config/micro/bindings.json`

Change the default keys you want to use.

Micro editor has a help file here https://github.com/zyedidia/micro/blob/master/runtime/help/keybindings.md

```json
{
"Alt-w": "lua:gutter.up",
"Alt-s": "lua:gutter.down",
"Alt-d": "lua:gutter.debugInfo"
}
```

## Raw key codes

Micro has a command `raw`

Micro will open a new tab and show the escape sequence for every event it receives from the terminal.

This shows you what micro actually sees from the terminal and helps you see which bindings aren't possible and why.

This is most useful for debugging keybindings.

Example

\x1b turns into \u001 then the same as the raw output.

`"\u001bctrlback": "DeleteWordLeft"`

Micro editor help file https://github.com/zyedidia/micro/blob/master/runtime/help/keybindings.md
