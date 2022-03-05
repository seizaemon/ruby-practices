#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'io/console/size'
require 'pathname'

OUTPUT_MAX_COLUMNS = 3

class String
  # 空白に換算したときの文字幅を計算する
  def space_size
    chars.map { |c| c.ascii_only? ? 1 : 2 }.sum
  end
end

class Array
  # 真偽値でsortの昇順・降順を切替
  def switch_sort(reverse: false)
    reverse ? sort.reverse : sort
  end
end

# main
def main
  # 出力する内容のフィルタフラグ
  filters = []

  opt = OptionParser.new
  # オプション処理
  opt.on('-a') { filters << 'SHOW_DOTMATCH' }
  opt.on('-r') { filters << 'SORT_REVERSE' }

  argv = opt.parse(ARGV)

  ls = Ls.new(filters)

  argv = ['./'] if argv.count.zero?
  ls.entries = argv
  ls.output
end

class Ls
  attr_writer :entries, :filters

  def initialize(filters = [])
    @filters = filters
    @entries = []
  end

  def output
    exclude_entries_nonexistent
    files = @entries.select { |entry| File.file?(entry) }
    dirs = @entries.select { |entry| File.directory?(entry) }

    # 実際のlsではファイルの出力が優先
    output_files(files)
    puts "\n" unless files.size.zero? || dirs.size.zero?
    if files.size.zero?
      output_dirs(dirs, force_label: (dirs.size != 1))
    else
      output_dirs(dirs, force_label: true)
    end
  end

  def exclude_entries_nonexistent
    @entries.select! do |entry|
      return true if File.exist?(entry)

      puts "ls: #{entry}: No such file or directory"
      false
    end
  end

  private

  def output_files(files)
    return if files.size.zero?

    formatted = create_formatted_list(format_entries(files.switch_sort(reverse: @filters.include?('SORT_REVERSE'))))
    output_common(formatted)
  end

  def output_dirs(dirs, force_label: false)
    force_label = true if dirs.size > 1

    dirs.switch_sort(reverse: @filters.include?('SORT_REVERSE')).each_with_index do |dir, index|
      entries_in_dir = Dir.glob('*', dir_filter_flags_sum, base: dir, sort: true)

      puts "\n" if index.positive?
      puts "#{dir}:" if force_label
      next if entries_in_dir.size.zero?

      formatted = create_formatted_list(format_entries(entries_in_dir.switch_sort(reverse: @filters.include?('SORT_REVERSE'))))

      output_common(formatted)
    end
  end

  def output_common(entry_list)
    entry_list.map(&:size).max.times do |n|
      row = []
      entry_list.each do |column|
        row << column[n] unless column[n].nil?
      end

      puts row.join(' ').rstrip if row.count.positive?
    end
  end

  def dir_filter_flags_sum
    result = 0
    result += File::FNM_DOTMATCH if @filters.include?('SHOW_DOTMATCH')
    result
  end

  def format_entries(entries)
    max_word_width = entries.map(&:space_size).max

    entries.map do |entry|
      num_of_chars = entry.size
      # 右に埋めるべき空白数
      spaces_of_completement = max_word_width - entry.space_size
      format("%-#{num_of_chars + spaces_of_completement}s", entry)
    end
  end

  def create_formatted_list(entries)
    return entries if entries.size.zero?

    num_of_columns = calc_num_of_columns(entries[0].space_size)
    format_list(entries, num_of_columns)
  end

  def calc_num_of_columns(word_length)
    return 1 if word_length > IO.console_size[1]

    # コンソールウインドウの幅に応じて列幅を調節する
    (1..OUTPUT_MAX_COLUMNS).to_a.reverse.find do |n|
      n * word_length <= IO.console_size[1]
    end
  end

  def format_list(entries, num_of_columns)
    columns = (1..num_of_columns).map { [] }
    max_rows = (entries.size.to_f / num_of_columns).ceil

    entries.each_with_index do |entry, index|
      column_index = index / max_rows
      if index == entries.size - 1 && columns.last.size.zero?
        columns.last.push entry
      else
        columns[column_index].push entry
      end
    end
    columns
  end
end

main if __FILE__ == $PROGRAM_NAME
