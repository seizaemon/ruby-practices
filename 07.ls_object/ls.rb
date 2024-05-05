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

  non_recursive_result = Screen.new(non_recursive_stats, options).show_files
  options[:header] = true if !non_recursive_result.nil? || recursive_stats.length > 1
  recursive_results = create_recursive_results(recursive_stats, options)

  puts [non_recursive_result, recursive_results].flatten.compact.join("\n\n")
end

def create_recursive_results(stats, options)
  stats.map do |stat|
    globed_files = Dir.glob('*', (options[:all_visible] ? File::FNM_DOTMATCH : 0), base: stat.name)
    globed_files << '..' if options[:all_visible]

    result = ''
    Dir.chdir(stat.name) do
      stats_in_dir = LsFileStat.bulk_create(globed_files, reverse: options[:reverse])
      result = Screen.new(stats_in_dir, options).recursive_show(base: stat.name)
    end

    result
  end
end

main
