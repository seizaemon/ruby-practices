#!/usr/bin/env ruby

# frozen_string_literal: true

require 'optparse'

def main
  line_opt = false

  opt = OptionParser.new
  opt.on('-l') { line_opt = true }

  opt.parse!(ARGV)

  # ARGFでファイルからの入力かパイプからの入力かを判断
  # https://docs.ruby-lang.org/ja/latest/class/ARGF.html
  if ARGF.argv.count.zero?
    # 標準入力
    wc = Wc.new(ARGF.gets(nil), line_only: line_opt)
    puts format_wc(wc.count_table, line_opt)
  else
    output_not_stdin(line_opt)
  end
end

def output_not_stdin(line_opt)
  init_argv_count = ARGV.count
  totals = Hash.new(0)

  while ARGF.argv.count.positive?
    wc = Wc.new(ARGF.gets(nil), line_only: line_opt)
    puts "#{format_wc(wc.count_table, line_opt)} #{ARGF.filename}"
    wc.count_table.each_pair { |k, v| totals[k] += v }
    ARGF.skip
  end
  return if init_argv_count == 1

  puts "#{format_wc(totals, line_opt)} total"
end

def format_wc(count_hash, line_only)
  keys = line_only ? %i[line] : %i[line word byte]
  keys.map { |k| format('%8d', count_hash[k]) }.join
end

class Wc
  attr_reader :count_table

  def initialize(input_str, line_only: false)
    @input_str = input_str
    @line_only = line_only
    @count_table = count_all
  end

  def count_all
    @line_only ? { line: line_count } : { line: line_count, word: word_count, byte: byte_count }
  end

  def line_count
    lines = @input_str.count("\n")
    # ファイル末尾の空行の扱い（末尾の空行はカウントしない）
    lines += 1 if @input_str.match?(/[^\n]\z/)
    lines
  end

  def word_count
    @input_str.scan(/\b*[^\s]+/).count
  end

  def byte_count
    @input_str.bytesize
  end
end

main if __FILE__ == $PROGRAM_NAME
