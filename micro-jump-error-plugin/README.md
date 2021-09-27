# Introduction

This is a simple jump to errors plugin for the [Micro](https://github.com/zyedidia/micro) editor.

## Custom Key Bindings

Add a file, if not already created in `~/.config/micro/bindings.json`

Change the default keys you want to use.

Micro editor has a help file here https://github.com/zyedidia/micro/blob/master/runtime/help/keybindings.md

```json
{
"Alt-w": "lua:gutter.up",
"Alt-s": "lua:gutter.down",
"Alt-d": "lua:gutter.debugInfo",
"Alt-a": "lua:gutter.start"
}
```
