# Rust Plugin for Micro

This repository holds the Rust plugin for micro editor.

Check which version of micro you have.

```bash
micro --version
```

## Install Plugin

### Micro Version 1

``` bash
mkdir -p ~/.config/micro/plugins
git clone https://github.com/tommyshem/micro-rust-plugin.git ~/.config/micro/plugins/rust
```

### Micro Version 2

```bash
mkdir -p ~/.config/micro/plug
git clone -b micro-v2 https://github.com/tommyshem/micro-rust-plugin.git ~/.config/micro/plug/rust
```

This plugin will let you lint and format your code.

When installed, to view the help file.

<kbd>Ctrl</kbd> <kbd>e</kbd>

`help rust-plugin`
