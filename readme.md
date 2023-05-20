# HXPM - Haxe Project Manager

# About

HXPM is a modern, project manager for Haxe.

# Usage

```
Usage:
  hxpm init [<dir>]                   -  initialize project
  hxpm install <package> [<version>]  -  install package
  hxpm remove <package>               -  uninstall package
  hxpm install-dep                    -  install project dependencies
```

# Installation

```sh
# clone this repository.
git clone https://github.com/ikasoba/hxpm --depth 1
cd hxpm

# build
haxe build.hxml

# move
mkdir ~/.hxpm
mv ./haxe-output/Main ~/.hxpm/hxpm

# install path
echo "export PATH=$PATH:$HOME/.hxpm/hxpm" >> ~/.profile
```
