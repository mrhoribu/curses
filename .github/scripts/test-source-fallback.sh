#!/bin/sh
# Checks that a Ruby the native gems were not built for still installs curses,
# by falling back to the source gem and compiling it, with both RubyGems and
# Bundler. A fat gem whose Ruby range excluded the running Ruby used to make
# Bundler fail instead, which is why curses 1.4.0 stopped shipping them.
#
# Usage: .github/scripts/test-source-fallback.sh PLATFORM GEM_DIR
#
# GEM_DIR holds the source gem and the PLATFORM gem, of one version, and
# PLATFORM must be the platform of the running Ruby. Needs the ncurses
# development files to compile the source gem, and network access to install
# Bundler's dependencies. Run from the repository root; it deletes lib/ and
# ext/, so only run it in a throwaway checkout (CI).
set -eu

platform=$1
gem_dir=$(cd "$2" && pwd)

rm -rf lib ext

# shellcheck disable=SC2016 # Ruby code, not shell expansions
version=$(ruby -rrubygems/package -e '
  versions = Dir[File.join(ARGV[0], "curses-*.gem")].map { |g| Gem::Package.new(g).spec.version.to_s }.uniq
  abort "expected one version in #{ARGV[0]}, found #{versions}" unless versions.size == 1
  puts versions
' "$gem_dir")

# shellcheck disable=SC2016 # Ruby code, not shell expansions
check='
  spec = Gem.loaded_specs.fetch("curses")
  abort "picked the #{spec.platform} gem, expected the source gem" unless spec.platform.to_s == "ruby"
  require "curses"
  abort "loaded a precompiled binary" if $LOADED_FEATURES.grep(%r{/\d+\.\d+/curses\.so\z}).any?
  puts "#{ARGV[0]}: curses #{spec.version} (#{spec.platform}) on ruby #{RUBY_VERSION}, #{Curses::VERSION}"
'

# Without the native gem next to it, this would test nothing.
if [ ! -f "$gem_dir/curses-$version-$platform.gem" ]; then
  echo "no curses-$version-$platform.gem in $gem_dir" >&2
  exit 1
fi

# A gem server directory holding both gems, so RubyGems and Bundler resolve
# them the way they resolve a release on RubyGems.org.
repo=$(mktemp -d)
mkdir "$repo/gems"
cp "$gem_dir"/curses-*.gem "$repo/gems/"
gem generate_index --help >/dev/null 2>&1 || gem install --no-document rubygems-generate_index
gem generate_index --directory "$repo"

status=0

echo "--- gem install (RubyGems $(gem --version))"
if gem install --no-document --clear-sources --source "file://$repo/" -v "$version" curses &&
   ruby -e "gem 'curses', ARGV[1]; $check" RubyGems "$version"; then
  gem uninstall --all --executables --ignore-dependencies curses
else
  echo "FAILED: gem install" >&2
  status=1
fi

echo "--- bundle install (Bundler $(bundle --version))"
app=$(mktemp -d)
cat > "$app/Gemfile" <<GEMFILE
source "file://$repo/"
gem "curses", "$version"
GEMFILE
if ! (cd "$app" && bundle install && bundle exec ruby -e "$check" Bundler); then
  echo "FAILED: bundle install" >&2
  status=1
fi

exit $status
