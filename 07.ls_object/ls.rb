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

  return if entries[:dirs].empty?

  puts unless entries[:files].empty?
  entries[:dirs].each do |entry|
    puts "#{entry}:" unless entries[:files].empty? && entries[:no_existence].empty?
    puts "#{entry}:" unless entries[:dirs].count == 1
    print_dir_entry(entry, long_format, reverse, hidden)
  end
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

def print_dir_entry(base, long_format, reverse, hidden)
  return if base.empty?

  entry_names = Dir.glob('*', (hidden ? File::FNM_DOTMATCH : 0), base:)
  entry_names << '..' if hidden

  entry_list = LsFileStat.bulk_create(entry_names, base:, reverse:)
  dir_screen = Screen.new(entry_list[:stats])
  if long_format
    puts "total #{total_blocks(entry_list[:stats])}\n#{dir_screen.out_in_detail}"
  else
    puts dir_screen.out
  end
end

def total_blocks(entries)
  entries.sum(&:blocks)
end

main
