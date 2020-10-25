# Introduction

This is a simple snippet plugin for the [Micro](https://github.com/zyedidia/micro) editor.


## Check which version of micro editor you have

```bash
micro --version
```

## Install Jump Error Plugin

### From Micro Version 2

```bash
mkdir ~/.config/micro/plug
git clone https://github.com/tommyshem/micro-jump-error-plugin ~/.config/micro/plug/gutter-plugin
```

## Help inside micro editor for this plugin

When installed, to view the help file inside micro editor, type in below:

<kbd>Ctrl</kbd> <kbd>e</kbd>

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
