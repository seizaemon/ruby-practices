#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require_relative 'lib/file_entry'
require_relative 'lib/entry_list'
require_relative 'lib/screen'
require_relative 'lib/detail_screen'

entry_list_opts = { hidden: false, reverse: false }
long_format = false

opt = OptionParser.new
# オプション処理
opt.on('-a') { entry_list_opts[:hidden] = true }
opt.on('-r') { entry_list_opts[:reverse] = true }
opt.on('-l') { long_format = true }

argv = opt.parse(ARGV)
argv = ['.'] if argv.count.zero?

out = argv.map do |arg|
  entry_list = EntryList.new(arg, **entry_list_opts)
  screen = if long_format
             DetailScreen.new(entry_list)
           else
             Screen.new(entry_list)
           end
  if argv.length == 1
    "#{screen.out}\n"
  else
    "#{arg}:\n#{screen.out}\n"
  end
end
print out.join("\n")
