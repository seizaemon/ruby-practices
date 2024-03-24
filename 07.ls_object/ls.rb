#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require_relative 'lib/screen'
require_relative 'lib/ls_file_stat'

def main
  hidden = false
  reverse = false
  long_format = false

  opt = OptionParser.new
  opt.on('-a') { hidden = true }
  opt.on('-r') { reverse = true }
  opt.on('-l') { long_format = true }

  argv = opt.parse(ARGV)
  argv = ['.'] if argv.empty?

  entries = LsFileStat.bulk_create(argv, reverse:)

  warn_no_existence(entries[:no_existence])
  print_file_entries(entries[:files], long_format, reverse)
  puts unless entries[:dirs].empty?
  print_dir_entries(entries[:dirs], long_format, reverse, hidden)
end

def warn_no_existence(entries)
  # エラー表示だけはreverseフラグにかかわらず辞書順
  entries.sort.each do |entry|
    warn "ls: #{entry}: No such file or directory"
  end
end

def print_file_entries(entries, long_format, reverse)
  return if entries.empty?

  file_entries = LsFileStat.bulk_create(entries, reverse:)
  screen = Screen.new(file_entries[:stats])
  long_format ? puts(screen.out_in_detail) : puts(screen.out)
end

def print_dir_entries(dir_entries, long_format, reverse, hidden)
  return if dir_entries.empty?

  dir_entries.each do |base|
    entry_names = Dir.glob('*', (hidden ? File::FNM_DOTMATCH : 0), base:)
    entry_names << '..' if hidden

    entry_list = LsFileStat.bulk_create(entry_names, base:, reverse:)
    dir_screen = Screen.new(entry_list[:stats])
    out = if long_format
            "total #{total_blocks(entry_list[:stats])}\n#{dir_screen.out_in_detail}"
          else
            dir_screen.out
          end
    puts(dir_entries == ['.'] ? out : "#{base}:\n#{out}")
  end
end

def total_blocks(entries)
  entries.sum(&:blocks)
end

main
