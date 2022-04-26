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
    puts wc
  else
    output_not_stdin(line_opt)
  end
end

def output_not_stdin(line_opt)
  init_argv_count = ARGV.count
  totals = line_opt ? { line: 0 } : { line: 0, word: 0, byte: 0 }

  while ARGF.argv.count.positive?
    wc = Wc.new(ARGF.gets(nil), line_only: line_opt)
    puts "#{wc} #{ARGF.filename}"
    wc.result.each_pair { |k, v| totals[k] += v }
    ARGF.skip
  end
  return if init_argv_count == 1

  puts "#{totals.keys.map { |k| format('%8d', totals[k]) }.join} total"
end

class Wc
  attr_reader :result

  def initialize(input_str, line_only: false)
    @input_str = input_str
    @line_only = line_only
    @result = count
  end

  def to_s
    @result.keys.map { |k| format('%8d', @result[k]) }.join
  end

  def count
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
