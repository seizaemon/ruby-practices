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

  file_stats = LsFileStat.bulk_create(argv, reverse:)

  warn_no_existence(file_stats[:no_existence])
  print_file_stats(file_stats[:files], long_format)

  return if file_stats[:dirs].empty?

  puts unless file_stats[:files].empty?
  file_stats[:dirs].each do |stat|
    puts "#{stat.name}:" unless file_stats[:files].empty? && file_stats[:no_existence].empty?
    puts "#{stat.name}:" unless file_stats[:dirs].count == 1
    print_dir_stats(stat, long_format, reverse, hidden)
  end
end

def warn_no_existence(entries)
  # エラー表示だけはreverseフラグにかかわらず辞書順
  entries.sort.each do |entry|
    warn "ls: #{entry}: No such file or directory"
  end
end

def print_file_stats(file_stats, long_format)
  return if file_stats.empty?

  screen = Screen.new(file_stats)
  long_format ? puts(screen.out_in_detail) : puts(screen.out)
end

def print_dir_stats(dir_stat, long_format, reverse, hidden)
  file_names = Dir.glob('*', (hidden ? File::FNM_DOTMATCH : 0), base: dir_stat.name)
  file_names << '..' if hidden

  Dir.chdir(dir_stat.name) do
    stats = LsFileStat.bulk_create(file_names, reverse:)
    dir_screen = Screen.new(stats[:all])
    if long_format
      puts "total #{total_blocks(stats[:all])}\n#{dir_screen.out_in_detail}"
    else
      puts dir_screen.out
    end
  end
end

def total_blocks(file_stats)
  file_stats.sum(&:blocks)
end

main
