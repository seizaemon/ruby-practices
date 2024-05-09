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
  options[:header] = !(paths.length == 1 || paths.empty?)

  screen_src = { '' => [] }

  paths.each do |path|
    stat = LsFileStat.new(path)
    if stat.file?
      screen_src[''] << stat
    else
      screen_src[path] = bulk_create_stats(path, options)
    end
  end
  Screen.new(screen_src, options).show
end

def bulk_create_stats(base_path, options)
  globed_files = Dir.glob('*', (options[:all_visible] ? File::FNM_DOTMATCH : 0), base: base_path)
  globed_files << '..' if options[:all_visible]
  globed_files.map { |file| LsFileStat.new(file, base_path) }
end

main
