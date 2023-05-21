# HXPM - Haxe Project Manager

# About

HXPM is a modern, project manager for Haxe.

# Usage

```
Usage:
  hxpm init [<dir>]                        -  initialize project.
  hxpm install [-L] <package> [<version>]  -  install package.
                                              The -L option can be used to add libraries to build.hxml.
  hxpm remove <package>                    -  uninstall package.
  hxpm install-dep                         -  install project dependencies.
  hxpm version                             -  show hxpm version.
```

# Installation

```sh
# clone this repository.
git clone https://github.com/ikasoba/hxpm --depth 1 -b latest
cd hxpm

# build
haxelib install build.hxml
haxe build.hxml

# move
mkdir ~/.hxpm
mv ./haxe-output/Main ~/.hxpm/hxpm

# install path
echo "export PATH=$PATH:$HOME/.hxpm/hxpm" >> ~/.profile
```
