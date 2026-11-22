# frozen_string_literal: true

# Smoke test for an installed curses gem: opens a screen on a pseudo-terminal,
# draws to it and checks what reached the terminal. That needs the curses
# library to find the terminfo entry for TERM, which is the part a precompiled
# gem can get wrong, so it is worth more here than a bare require.
#
# Usage: ruby smoke_test.rb [TERM...]
# With no arguments, tests xterm-256color.

require "pty"
require "timeout"

terms = ARGV.empty? ? ["xterm-256color"] : ARGV

CHILD = <<~'RUBY'
  require "curses"
  Curses.init_screen
  begin
    Curses.start_color if Curses.has_colors?
    # A menu posted on stdscr is erased from it again by unpost, so this
    # comes before the drawing that is checked below.
    if defined?(Curses::Menu)
      menu = Curses::Menu.new([Curses::Item.new("menu item", "")])
      menu.post
      menu.unpost
    end
    Curses.setpos(0, 0)
    Curses.addstr("curses smoke test")
    win = Curses::Window.new(3, 20, 2, 0)
    win.box("|", "-")
    win.setpos(1, 1)
    win.addstr("window")
    Curses.refresh
    win.refresh
  ensure
    Curses.close_screen
  end
  puts
  # Curses::VERSION is the version of the curses library, not of the gem.
  puts "ok #{Curses::VERSION} " \
       "menu=#{!!defined?(Curses::Menu)} form=#{!!defined?(Curses::Form)}"
RUBY

terms.each do |term|
  output = +""
  status = nil
  env = { "TERM" => term, "LINES" => "24", "COLUMNS" => "80" }
  Timeout.timeout(60) do
    PTY.spawn(env, RbConfig.ruby, "-e", CHILD) do |r, _w, pid|
      begin
        loop { output << r.readpartial(4096) }
      rescue EOFError, Errno::EIO
        # The child closed the terminal.
      end
      _, status = Process.wait2(pid)
    end
  end
  text = output.gsub(/\e\[[0-9;?]*[A-Za-z]|\e[()][0-9A-Za-z]|\e[=>]/, "")
  abort "TERM=#{term}: child failed (#{status.inspect}):\n#{output.inspect}" unless status.success?
  %w[curses\ smoke\ test window].each do |expected|
    abort "TERM=#{term}: #{expected.inspect} not drawn:\n#{output.inspect}" unless text.include?(expected)
  end
  abort "TERM=#{term}: no escape sequences, so no terminfo entry was used:\n#{output.inspect}" unless output.include?("\e[")
  puts "TERM=#{term}: #{text[/^ok .*/]}"
end
