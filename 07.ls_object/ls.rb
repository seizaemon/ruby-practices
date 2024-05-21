#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require_relative 'lib/ls_object'

options = {}

opt = OptionParser.new
opt.on('-a') { options[:all_visible] = true }
opt.on('-r') { options[:reverse] = true }
opt.on('-l') { options[:long_format] = true }

ls_object = LsObject.new(opt.parse(ARGV), options)

ls_object.main
