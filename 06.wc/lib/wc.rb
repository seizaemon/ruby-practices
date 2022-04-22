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
    output_not_stdin(line_opt)
  end
end

def output_not_stdin(line_opt)
  totals = line_opt ? { 'lines': 0, 'words': nil, 'bytes': nil } : { 'lines': 0, 'words': 0, 'bytes': 0 }
  init_argv_count = ARGV.count

  while ARGF.argv.count.positive?
    wc = Wc.new(ARGF.gets(nil))
    totals[:lines] += wc.lines
    unless line_opt
      totals[:words] += wc.words
      totals[:bytes] += wc.bytes
    end
    puts "#{wc.output(line_only: line_opt)} #{ARGF.filename}"
    ARGF.skip
  end
  puts "#{%i[lines words bytes].map { |key| format('%8d', totals[key]) if totals[key] }.join} total" if init_argv_count > 1
end

class Wc
  def initialize(input_str)
    @input_str = input_str
    @lines = nil
    @words = nil
    @bytes = nil
  end

  def output(line_only: false)
    lines
    unless line_only
      words
      bytes
    end
    [@lines, @words, @bytes].map { |element| format('%8d', element) if element }.join
  end

  def lines
    @lines ||= begin
      lines = @input_str.count("\n")
      # ファイル末尾の空行の扱い（末尾の空行はカウントしない）
      lines += 1 if @input_str.match?(/[^\n]\z/)
      lines
    end
  end

  def words
    @words ||= @input_str.scan(/\b*[^\s]+/).count
  end

  def bytes
    @bytes ||= @input_str.bytesize
  end
end

main if __FILE__ == $PROGRAM_NAME
