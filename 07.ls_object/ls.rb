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
  options[:header] = true

  paths = opt.parse(ARGV)
  paths << '.' if paths.empty?
  options[:header] = false if paths.length == 1

  stats = LsFileStat.bulk_create(paths, reverse: options[:reverse])
  normal_stats = stats.reject(&:directory?)
  recursive_stats = stats.select(&:directory?)

  Screen.new(normal_stats, options).show
  return if recursive_stats.empty?

  puts if !normal_stats.empty? # セパレータ
  Screen.new(recursive_stats, options).recursive_show
end

main
