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
  options[:header] = !(paths.length == 1 || paths.empty?)
  paths << '.' if paths.empty?

  screen_src = { '' => [] }

  sort_paths(paths, reverse: options[:reverse]).each do |path_name|
    stat = LsFileStat.new(path_name)
    if stat.file?
      screen_src[''] << stat
    else
      screen_src[path_name.to_s] = create_stats_in_directory(path_name, options)
    end
  end

  Screen.new(screen_src, options).show
end

def create_stats_in_directory(base_path_name, options)
  paths = Dir.glob('*', (options[:all_visible] ? File::FNM_DOTMATCH : 0), base: base_path_name.to_s)
  paths << '..' if options[:all_visible]
  sort_paths(paths, base_path_name.to_s, reverse: options[:reverse]).map do |path_name|
    LsFileStat.new(path_name)
  end
end

def sort_paths(paths, base_path = '.', reverse: false)
  sorted_paths = reverse ? paths.sort.reverse : paths.sort
  sorted_paths.map { |path| Pathname.new(base_path).join(path) }
end

main
