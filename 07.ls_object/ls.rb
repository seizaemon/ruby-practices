#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require_relative 'lib/entry_list'
require_relative 'lib/screen'
require_relative 'lib/detail_screen'

hidden = false
reverse = false
long_format = false

opt = OptionParser.new
opt.on('-a') { hidden = true }
opt.on('-r') { reverse = true }
opt.on('-l') { long_format = true }

argv = opt.parse(ARGV)
argv = ['.'] if argv.count.zero?

out = []
error = []

# 存在しないエントリはここで除去
argv.select! do |arg|
  File.lstat(arg)
  true
rescue Errno::ENOENT
  error << "ls: #{arg}: No such file or directory"
  false
end

# ディレクトリを指定した場合は中身を展開してEntryListを作成する
dir_entries = argv.select { |arg| File.lstat(arg).ftype == 'directory' }

# 引数がファイルの場合
entry_list = EntryList.new(
  argv.reject { |arg| File.lstat(arg).ftype == 'directory' },
  reverse:
)
screen = long_format ? DetailScreen.new(entry_list) : Screen.new(entry_list)
out << screen.out.to_s

# 引数がディレクトリの場合
# TODO: もっとシンプルに
## dir_entries内のentryは一つ一つ中身を展開して渡す
unless dir_entries.nil? || dir_entries.empty?
  reverse ? dir_entries.sort.reverse! : dir_entries.sort!

  dir_entries.each do |entry|
    entries = Dir.glob('*', (hidden ? File::FNM_DOTMATCH : 0), base: entry)
    entries << '..' if hidden

    entry_list = EntryList.new(entries, base: entry, reverse:)
    dir_screen = long_format ? DetailScreen.new(entry_list) : Screen.new(entry_list)

    out << (argv.length == 1 && error.empty? ? "#{dir_screen.out}\n" : "\n#{entry}:\n#{dir_screen.out}\n")
  end
end

$stderr.print error.sort.join("\n") unless error.empty?
print out.join("\n")
