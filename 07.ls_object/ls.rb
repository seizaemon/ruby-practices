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
  paths = ['.'] if argv.empty?

  stats = LsFileStat.bulk_create(paths, reverse:)
  file_stats = stats.map(&:file?)
  dir_stats = stats.map(&:directory?)

  print_file_stats(file_stats, long_format)

  unless stats[:dirs].empty?
    puts unless stats[:files].empty?
    dir_stats.each do |stat|
      # エラー時の表示制御は省略しました
      if not file_stats.empty? && dir_stats.count == 1
        puts "#{stat.name}:"
      end
      print_dir_stats(stat, long_format, reverse, all_visible)
    end
  end
end

def print_file_stats(file_stats, long_format)
  return if file_stats.empty?

  screen = Screen.new(file_stats)
  if long_format
    puts(screen.out_in_detail)
  else
    puts(screen.out)
  end
end

def print_dir_stats(dir_stat, long_format, reverse, all_visible)
  file_names = Dir.glob('*', (all_visible ? File::FNM_DOTMATCH : 0), base: dir_stat.name)
  file_names << '..' if all_visible

  Dir.chdir(dir_stat.name) do
    stats = LsFileStat.bulk_create(file_names, reverse:)
    screen = Screen.new(stats)
    if long_format
      puts <<~EOS
        total #{stats.sum(&:blocks)}
        #{screen.out_in_detail}"
      EOS
    else
      puts screen.out
    end
  end
end

main
