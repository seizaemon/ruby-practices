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
    wc = Wc.new(ARGF.gets(nil))
    puts wc.output(line_only: line_opt)
  else
    lines_total = 0
    init_argv_count = ARGV.count
    while ARGF.argv.count.positive?
      wc = Wc.new(ARGF.gets(nil))
      lines_total += wc.lines
      puts "#{wc.output(line_only: line_opt)} #{ARGF.filename}"
      ARGF.skip
    end
    puts "#{format('%8d', lines_total)} total" if line_opt && init_argv_count > 1
  end
end

class Wc
  attr_reader :lines, :words, :bytes

  def initialize(input_str)
    @input_str = input_str
    @lines = count_line
    @words ||= count_word
    @bytes ||= count_byte
  end

  def output(line_only: false)
    if line_only
      format('%8d', @lines)
    else
      [@lines, @words, @bytes].map { |e| format('%8d', e) }.join('')
    end
  end

  private

  def count_line
    lines = @input_str.count("\n")
    # ファイル末尾の空行の扱い（末尾の空行はカウントしない）
    lines += 1 if @input_str.match?(/[^\n]\z/)
    lines
  end

  def count_word
    @input_str.scan(/\b*[^\s]+/).count
  end

  def count_byte
    @input_str.bytesize
  end
end

main if __FILE__ == $PROGRAM_NAME
