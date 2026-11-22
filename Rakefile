require "bundler"

Bundler::GemHelper.install_tasks

begin
  require "rdoc/task"
  RDoc::Task.new do |doc|
    doc.main   = "README.md"
    doc.title  = "Curses: A Ruby binding for curses, ncurses, and PDCurses."
    doc.rdoc_files = FileList.new %w[ext/curses/curses.c lib README.md BSDL COPYING]
    doc.rdoc_dir = "_site" # for github pages
  end
rescue LoadError
end

# Platforms that get a precompiled native gem, published alongside the source
# gem so that most users can install curses without a C compiler or the
# ncurses development files. Each one is built in a rake-compiler-dock
# container; see the gem:native tasks below and
# .github/workflows/precompiled.yml.
#
# The Windows gems link the bundled PDCursesMod statically, as a source
# install on Windows does. The Linux and macOS gems link a static ncurses
# built by extconf.rb (--enable-vendored-ncurses), so they need no ncurses
# shared library on the system, only its terminfo database.
#
# The *-linux-gnu and *-linux-musl gems are built separately because the
# rake-compiler-dock docs say not to mix a bare *-linux gem with *-linux-musl.
NATIVE_PLATFORMS = %w[
  aarch64-linux-gnu
  aarch64-linux-musl
  aarch64-mingw-ucrt
  arm-linux-gnu
  arm-linux-musl
  arm64-darwin
  x64-mingw-ucrt
  x86-linux-gnu
  x86-linux-musl
  x86_64-darwin
  x86_64-linux-gnu
  x86_64-linux-musl
]

# Ruby minor versions compiled into each native gem. Other Rubies fall back to
# the source gem and compile it as before.
NATIVE_RUBY_VERSIONS = %w[4.0 3.4 3.3 3.2 3.1]

# RubyInstaller for Windows on ARM64, and so rake-compiler-dock's cross rubies
# for it, start at Ruby 3.4.
NATIVE_RUBY_VERSIONS_FOR = Hash.new(NATIVE_RUBY_VERSIONS).merge(
  "aarch64-mingw-ucrt" => %w[4.0 3.4]
)

# Binaries rake-compiler-dock leaves unstripped, and the strip that fixes them.
# Its cross rubies are linked with -s everywhere but Windows ARM64 and macOS,
# and extensions inherit that.
NATIVE_STRIP = {
  "aarch64-mingw-ucrt" => "aarch64-w64-mingw32-strip --strip-all",
  "arm64-darwin" => "aarch64-apple-darwin-strip -x",
  "x86_64-darwin" => "x86_64-apple-darwin-strip -x",
}

begin
  require "rake/extensiontask"
rescue LoadError
  # rake-compiler is only needed to build the extension with rake (rake
  # compile) or to build the precompiled gems.
else
  spec = Gem::Specification.load(File.expand_path("curses.gemspec", __dir__))

  Rake::ExtensionTask.new("curses", spec) do |ext|
    ext.cross_compile = true
    ext.cross_platform = NATIVE_PLATFORMS
    ext.cross_config_options << NATIVE_PLATFORMS.grep(/linux|darwin/).to_h do |platform|
      [platform, "--enable-vendored-ncurses"]
    end
    ext.cross_compiling do |native_spec|
      # The native gem ships compiled binaries, one per Ruby version under
      # lib/<major.minor>/, so it needs neither the C sources nor
      # extconf.rb, nor PDCursesMod's sources. It does carry the license of
      # the ncurses it links.
      native_spec.files.reject! do |path|
        path.start_with?("ext/", "vendor/")
      end
      if /linux|darwin/ =~ native_spec.platform.to_s
        native_spec.files << "vendor/ncurses/COPYING"
      end
    end
  end

  # Strip each binary in NATIVE_STRIP as soon as it is compiled. Only inside
  # the rake-compiler-dock container (which sets RCD_HOST_RUBY_PLATFORM),
  # where the strip tools are.
  if ENV["RCD_HOST_RUBY_PLATFORM"]
    Rake::Task.tasks.each do |task|
      platform = task.name[%r{\Atmp/([^/]+)/curses/\d+\.\d+\.\d+/curses\.(?:so|bundle)\z}, 1]
      strip = NATIVE_STRIP[platform] or next

      task.enhance { sh "#{strip} #{task.name}" }
    end
  end

  # Gem::PackageTask defines the gem task that rake-compiler hooks to package
  # the native gems into pkg/.
  require "rubygems/package_task"
  Gem::PackageTask.new(spec).define

  namespace :gem do
    namespace :native do
      NATIVE_PLATFORMS.each do |platform|
        desc "Build the precompiled #{platform} gem with rake-compiler-dock"
        task platform do
          require "rake_compiler_dock"
          RakeCompilerDock.set_ruby_cc_version(*NATIVE_RUBY_VERSIONS_FOR[platform])
          # The container image ships rake-compiler and the cross rubies, so
          # this runs plain rake rather than bundle exec.
          RakeCompilerDock.sh("rake native:#{platform} gem RUBY_CC_VERSION=#{ENV.fetch('RUBY_CC_VERSION')}",
                              platform: platform)
        end
      end
    end

    desc "Build the precompiled gems for every native platform"
    task native: NATIVE_PLATFORMS.map { |platform| "gem:native:#{platform}" }
  end
end
