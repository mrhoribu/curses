# curses

[![Gem Version](https://badge.fury.io/rb/curses.svg)](https://badge.fury.io/rb/curses)
[![ubuntu](https://github.com/ruby/curses/workflows/ubuntu/badge.svg)](https://github.com/ruby/curses/actions?query=workflow%3Aubuntu)
[![windows](https://github.com/ruby/curses/workflows/windows/badge.svg)](https://github.com/ruby/curses/actions?query=workflow%3Awindows)
[![macos](https://github.com/ruby/curses/workflows/macos/badge.svg)](https://github.com/ruby/curses/actions?query=workflow%3Amacos)

* https://github.com/ruby/curses
* https://github.com/ruby/curses/issues

## Description

A Ruby binding for curses, ncurses, and PDCurses.
curses is an extension library for text UI applications.

Formerly part of the Ruby standard library, [curses was removed and placed in this gem][1]
with the release of Ruby 2.1.0. (see [ruby/ruby@9c5b2fd][2])

## Install

    $ gem install curses

Precompiled native gems are published for Linux (x86_64, aarch64, x86 and
32-bit arm, each with glibc or musl), macOS (x86_64 and arm64) and Windows
(x64 and ARM64), so on those platforms no C compiler or curses library is
needed. They cover Ruby 3.1 through 4.0, except Windows ARM64, which starts
at Ruby 3.4 as RubyInstaller does.

The Linux and macOS gems include a static build of ncurses 6.6 with wide
character support, so `Curses::Menu` and `Curses::Form` are always
available. It reads terminal descriptions from the system's terminfo
database (`/etc/terminfo`, `/lib/terminfo`, `/usr/share/terminfo` or
`/usr/lib/terminfo`, or the directory in `$TERMINFO`), so a system without
one, such as a minimal container image, needs a package that provides it,
for example `ncurses-base` on Debian or `ncurses-terminfo-base` on Alpine.
The Windows gems include PDCursesMod, as a source install on Windows does.

Other platforms and Rubies install the source gem and compile the extension,
as described below. To always compile from source (for example, to link the
system's ncurses), use `gem install curses --platform ruby`, or with Bundler
set `force_ruby_platform: true` on the gem or run
`bundle config set force_ruby_platform true`.

The source gem requires ncurses or ncursesw (with wide character support).
On Debian based distributions, you can install it with apt:

    $ apt install libncurses5-dev

Or

    $ apt install libncursesw5-dev

On Windows, `gem install curses` will build bundled PDCurses, so you
don't need to install extra libraries.
However, if you prefer ncurses to PDCurses, specify the following option:

    > gem install curses -- --use-system-libraries

On mingw, you need DevKit to compile the extension library.

On MacOS, `ncurses` menu isn't natively supported. You can install the gem with menu support using homebrew:

    brew install ncurses
    gem install curses -- --use-system-libraries --with-ncurses-dir=/usr/local/opt/ncurses

_with `/usr/local/opt/ncurses` the path where homebrew installed ncurses on your machine_

## Documentation

Type the following command, and see `[rdoc]` of curses:

    gem install rubygems-server
    gem server -l

## Limitations

* On ncurses 6+ compiled with extended color support, more than 256 color pairs are supported transparently via the extended colors API (`init_extended_pair`, etc.). Use `Curses.support_extended_colors?` to check at runtime.

## Developers

After checking out the repo, run `bundle install` to install dependencies.

To compile the extension library, run `bundle exec rake compile`.

To build the precompiled native gems into `pkg/`, run
`bundle exec rake gem:native` (all platforms) or
`bundle exec rake gem:native:<platform>`. This needs Docker, as the gems are
built in [rake-compiler-dock](https://github.com/rake-compiler/rake-compiler-dock)
containers; the Linux and macOS builds download ncurses.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `curses.gemspec`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## License

curses is released under the Ruby and 2-clause BSD licenses.  See COPYING for
details.

It includes PDCursesMod, which is in the public domain:

  https://github.com/Bill-Gray/PDCursesMod

The version for Win32 console mode in the wincon subdirectory is used.

The precompiled Linux and macOS gems include ncurses, which is released under
an MIT-style license; see `vendor/ncurses/COPYING`:

  https://invisible-island.net/ncurses/

[1]: https://bugs.ruby-lang.org/issues/8584
[2]: https://github.com/ruby/ruby/commit/9c5b2fd8aa0fd343ad094d47a638cfd3f6ae0a81
