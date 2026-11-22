#!/bin/sh
# Installs a precompiled curses gem and checks that it works.
#
# Usage: .github/scripts/test-installed-gem.sh PLATFORM GEM_DIR
#
# GEM_DIR holds the source gem and the PLATFORM gem, of one version. curses is
# installed by name and version, as a user would, so this also checks that
# RubyGems picks the native gem over the source gem.
#
# Run from the repository root. It deletes lib/ and ext/ first so nothing
# in-tree can be loaded, so only run it in a throwaway checkout (CI).
set -eu

platform=$1
gem_dir=$2

rm -rf lib ext

# Install the version under test by name. Naming the version is what lets a
# prerelease install at all; RubyGems skips prereleases when asked for just a
# name, even with --prerelease.
# shellcheck disable=SC2016 # Ruby code, not shell expansions
version=$(ruby -rrubygems/package -e '
  versions = Dir[File.join(ARGV[0], "curses-*.gem")].map { |g| Gem::Package.new(g).spec.version.to_s }.uniq
  abort "expected one version in #{ARGV[0]}, found #{versions}" unless versions.size == 1
  puts versions
' "$gem_dir")
(cd "$gem_dir" && gem install --local --no-document -v "$version" curses)

# Fail if RubyGems picked the source gem, or if curses did not load the binary
# built for this Ruby's minor version, or if that binary is not linked against
# the curses library the native gem bundles. The version is pinned so another
# installed curses can not stand in for this one.
# shellcheck disable=SC2016 # Ruby code, not shell expansions
ruby -e '
  gem "curses", ARGV[1]
  spec = Gem.loaded_specs.fetch("curses")
  abort "RubyGems picked the source gem over the #{ARGV[0]} gem" if spec.platform.to_s == "ruby"
  abort "the native gem still declares extensions: #{spec.extensions}" unless spec.extensions.empty?
  require "curses"
  loaded = $LOADED_FEATURES.grep(%r{/\d+\.\d+/curses\.(so|bundle)\z})
  abort "did not load a precompiled binary" if loaded.empty?
  library = /mingw/.match?(ARGV[0]) ? /\APDCursesMod / : /\Ancurses 6\.6\./
  abort "linked against #{Curses::VERSION}, expected #{library.source}" unless library.match?(Curses::VERSION)
  puts "curses #{spec.version} (#{spec.platform}) on ruby #{RUBY_VERSION}: #{loaded.first}, #{Curses::VERSION}"
' "$platform" "$version"

case $platform in
  *mingw*)
    # PDCursesMod draws through the Windows console API, not a terminal, so
    # there is no output stream to check here.
    ;;
  *)
    # The ruby:3.3-alpine and later images have no terminfo database (the
    # earlier ones get ncurses-terminfo-base through readline), so install
    # it as the README tells users to.
    if [ -f /etc/alpine-release ] &&
       [ ! -e /etc/terminfo/x/xterm-256color ] &&
       [ ! -e /usr/share/terminfo/x/xterm-256color ]; then
      echo "No terminfo database; installing ncurses-terminfo-base"
      apk add --no-cache ncurses-terminfo-base
    fi
    # Draw on a pseudo-terminal with a few common terminal types. The
    # vendored ncurses must find each one in the system's terminfo database.
    ruby .github/scripts/smoke_test.rb xterm-256color xterm vt100 linux screen
    ;;
esac
