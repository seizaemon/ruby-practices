#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require_relative 'lib/screen'
require_relative 'lib/ls_file_stat'

def main
  options = {}

  opt = OptionParser.new
  opt.on('-a') { options[:all_visible] = true }
  opt.on('-r') { options[:reverse] = true }
  opt.on('-l') { options[:long_format] = true }

  paths = opt.parse(ARGV)
  paths << '.' if paths.empty?

  stats = LsFileStat.bulk_create(paths, reverse: options[:reverse])
  non_recursive_stats = stats.reject(&:directory?)
  recursive_stats = stats.select(&:directory?)

  non_recursive_output = Screen.new(non_recursive_stats, options).show_files
  options[:header] = true if !non_recursive_output.nil? || recursive_stats.length > 1
  recursive_outputs = create_recursive_output(recursive_stats, options)

  puts [non_recursive_output, recursive_outputs].compact.join("\n\n")
end

def create_recursive_output(stats, options)
  return nil if stats.empty?

  stats.map do |stat|
    file_names = Dir.glob('*', (options[:all_visible] ? File::FNM_DOTMATCH : 0), base: stat.name)
    file_names << '..' if options[:all_visible]

    recursive_out = ''
    Dir.chdir(stat.name) do
      stats_in_dir = LsFileStat.bulk_create(file_names, reverse: options[:reverse])
      recursive_out = Screen.new(stats_in_dir, options).recursive_show(base: stat.name)
    end

    recursive_out
  end
end

main
