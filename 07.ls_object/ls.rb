#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require_relative 'lib/screen'
require_relative 'lib/ls_file_stat'

def main
  all_visible = false
  reverse = false
  long_format = false

  opt = OptionParser.new
  opt.on('-a') { all_visible = true }
  opt.on('-r') { reverse = true }
  opt.on('-l') { long_format = true }

  paths = opt.parse(ARGV)
  paths = ['.'] if paths.empty?

  stats = LsFileStat.bulk_create(paths, reverse:)
  file_stats = stats.filter(&:file?)
  dir_stats = stats.filter(&:directory?)

  print_file_stats(file_stats, long_format)

  puts unless file_stats.empty?
  dir_stats.each do |stat|
    # エラー時の表示制御は省略
    puts "#{stat.name}:" if !file_stats.empty? && dir_stats.count == 1
    print_dir_stats(stat, long_format, reverse, all_visible)
  end
end

def print_file_stats(file_stats, long_format)
  return if file_stats.empty?

  screen = Screen.new(file_stats)
  if long_format
    print screen.rows_out_in_detail
  else
    print screen.rows_out
  end
end

def print_dir_stats(dir_stat, long_format, reverse, all_visible)
  file_names = Dir.glob('*', (all_visible ? File::FNM_DOTMATCH : 0), base: dir_stat.name)
  file_names << '..' if all_visible

  Dir.chdir(dir_stat.name) do
    stats = LsFileStat.bulk_create(file_names, reverse:)
    screen = Screen.new(stats)
    if long_format
      puts "total #{stats.map(&:blocks).sum}"
      # ブロック単位になるputsの改行が効かない
      print screen.rows_out_in_detail
    else
      print screen.rows_out
    end
  end
end

main
