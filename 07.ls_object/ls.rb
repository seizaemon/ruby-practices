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

  return if dir_stats.empty?

  label = !file_stats.empty? ? true : false
  separator = !file_stats.empty? ? true : false
  print_dir_stats dir_stats, long_format, reverse, all_visible, label:, separator:
end

def print_file_stats(file_stats, long_format)
  return if file_stats.empty?

  screen = Screen.new(file_stats)
  if long_format
    puts screen.out_in_detail
  else
    puts screen.out
  end
end

def print_dir_stats(dir_stats, *options, label: false, separator: false)
  puts if separator
  out = if label
          dir_stats.map do |stat|
            <<~TEXT
              #{stat.name}:
              #{show_dir_stat(stat, *options)}
            TEXT
          end
        else
          dir_stats.map { |stat| show_dir_stat stat, *options }
        end
  puts out.join("\n")
end

def show_dir_stat(dir_stat, long_format, reverse, all_visible)
  file_names = Dir.glob('*', (all_visible ? File::FNM_DOTMATCH : 0), base: dir_stat.name)
  file_names << '..' if all_visible

  return if file_names.empty?

  Dir.chdir(dir_stat.name) do
    stats = LsFileStat.bulk_create(file_names, reverse:)
    screen = Screen.new(stats)
    if long_format
      <<~TEXT
        total #{stats.map(&:blocks).sum}
        #{screen.out_in_detail}
      TEXT
    else
      screen.out
    end
  end
end

main
