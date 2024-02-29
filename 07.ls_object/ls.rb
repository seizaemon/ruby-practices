#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require_relative 'lib/entry_list'
require_relative 'lib/screen'

hidden = false
reverse = false
long_format = false

opt = OptionParser.new
opt.on('-a') { hidden = true }
opt.on('-r') { reverse = true }
opt.on('-l') { long_format = true }

argv = opt.parse(ARGV)
argv = ['.'] if argv.empty?

entry_list = EntryList.new(argv, reverse:)

# エラー表示だけはreverseフラグにかかわらず辞書順
entry_list.no_existence.sort.each do |entry|
  warn "ls: #{entry}: No such file or directory"
end

unless entry_list.files.empty?
  screen = Screen.new(EntryList.new(entry_list.files, reverse:))

  long_format ? puts(screen.out_in_detail) : puts(screen.out)
  puts unless entry_list.dirs.empty?
end

unless entry_list.dirs.empty?
  entry_list.dirs.each do |base|
    entry_names = Dir.glob('*', (hidden ? File::FNM_DOTMATCH : 0), base:)
    entry_names << '..' if hidden

    dir_screen = Screen.new(EntryList.new(entry_names, base:, reverse:))
    out = long_format ? dir_screen.out_in_detail : dir_screen.out

    puts(argv.length == 1 ? out : "#{base}:\n#{out}")
  end
end
