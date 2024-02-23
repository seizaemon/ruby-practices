#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require_relative 'lib/entry_list'
require_relative 'lib/screen'
require_relative 'lib/detail_screen'

hidden = false
reverse = false
long_format = false

opt = OptionParser.new
opt.on('-a') { hidden = true }
opt.on('-r') { reverse = true }
opt.on('-l') { long_format = true }

argv = opt.parse(ARGV)
argv = ['.'] if argv.empty?

file_out = []
dir_out = []
error_out = []

existed = argv.select do |arg|
  File.lstat(arg)
  true
rescue Errno::ENOENT
  error_out << "ls: #{arg}: No such file or directory"
  false
end

dir_entries = existed.select { |arg| File.lstat(arg).ftype == 'directory' }

file_entries = EntryList.new(
  existed.reject { |arg| File.lstat(arg).ftype == 'directory' },
  reverse:
)
unless file_entries.empty?
  screen = long_format ? DetailScreen.new(file_entries) : Screen.new(file_entries)
  file_out << screen.out
end

unless dir_entries.empty?
  reverse ? dir_entries.sort.reverse! : dir_entries.sort!

  dir_entries.each do |entry|
    entries = Dir.glob('*', (hidden ? File::FNM_DOTMATCH : 0), base: entry)
    entries << '..' if hidden

    entry_list = EntryList.new(entries, base: entry, reverse:)
    dir_screen = long_format ? DetailScreen.new(entry_list) : Screen.new(entry_list)

    dir_out << (argv.length == 1 ? dir_screen.out : "#{entry}:\n#{dir_screen.out}")
  end
end

warn error_out.sort.join("\n") unless error_out.empty?
unless file_out.empty?
  puts file_out.join("\n")
  puts unless dir_out.empty?
end
puts dir_out.join("\n\n") unless dir_out.empty?
