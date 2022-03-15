#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'io/console/size'
require 'pathname'
require 'etc'
require 'debug'

OUTPUT_MAX_COLUMNS = 3

class String
  # 空白に換算したときの文字幅を計算する
  def space_size
    chars.map { |c| c.ascii_only? ? 1 : 2 }.sum
  end

  def type_conv
    types = {
      '1' => 'p', # FIFO
      '2' => 'c', # Character Special
      '4' => 'd', # Directory
      '6' => 'b', # Block Special
      '10' => '-', # Regular file
      '12' => 'l', # Symbolic link
      '14' => 's' # Socket
    }
    types[self]
  end

  def mode_conv
    mode = {
      '0' => '---',
      '1' => '--x',
      '2' => '-w-',
      '3' => '-wx',
      '4' => 'r--',
      '5' => 'r-x',
      '6' => 'rw-',
      '7' => 'rwx'
    }
    mode[self]
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
  long_format = false

  opt = OptionParser.new
  # オプション処理
  opt.on('-a') { filters << :SHOW_DOTMATCH }
  opt.on('-r') { filters << :SORT_REVERSE }
  opt.on('-l') { long_format = true }

  argv = opt.parse(ARGV)

  ls = long_format ? LsLong.new(filters) : Ls.new(filters)

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
    files = @entries.select { |entry| File.file?(entry) || !%r{/$}.match(entry) }
    dirs = @entries.select { |entry| File.directory?(entry) && %r{/$}.match(entry) }

    # 実際のlsではファイルの出力が優先
    output_files(files)
    puts "\n" unless files.size.zero? || dirs.size.zero?
    files.size.zero? ? output_dirs(dirs, force_label: (dirs.size != 1)) : output_dirs(dirs, force_label: true)
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

    formatted = create_formatted_list(format_entries(files.switch_sort(reverse: @filters.include?(:SORT_REVERSE))))
    puts output_common(formatted).join("\n")
  end

  def output_dirs(dirs, force_label: false)
    return if dirs.size.zero?

    force_label ||= (dirs.size > 1)

    output = dirs.switch_sort(reverse: @filters.include?(:SORT_REVERSE)).map do |dir|
      entries_in_dir = Dir.glob('*', dir_filter_flags_sum, base: dir, sort: true)
      result = force_label ? ["#{dir}:"] : []
      next result.join("\n") if entries_in_dir.size.zero?

      formatted = create_formatted_list(format_entries(entries_in_dir.switch_sort(reverse: @filters.include?(:SORT_REVERSE))))
      result << output_common(formatted)
      result.join("\n")
    end
    puts output.join("\n\n") unless output.all?(&:empty?)
  end

  def output_common(entry_list)
    result = []
    entry_list.map(&:size).max.times do |n|
      row = entry_list.each_with_object([]) do |column, row_of_columns|
        row_of_columns << column[n] unless column[n].nil?
      end
      result << row.join(' ').rstrip if row.size.positive?
    end
    result
  end

  def dir_filter_flags_sum
    result = 0
    result += File::FNM_DOTMATCH if @filters.include?(:SHOW_DOTMATCH)
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

class LsLong < Ls
  private

  def output_files(files)
    return if files.size.zero?

    formatted = format_entries(files.switch_sort(reverse: @filters.include?(:SORT_REVERSE)))
    formatted.each { |line| puts line }
  end

  def output_dirs(dirs, force_label: false)
    return if dirs.size.zero?

    force_label ||= (dirs.size > 1)

    output = dirs.switch_sort(reverse: @filters.include?(:SORT_REVERSE)).map do |dir|
      entries_in_dir = Dir.glob('*', dir_filter_flags_sum, base: dir, sort: true)
      result = force_label ? ["#{dir}:"] : []
      # 各ディレクトリのブロック数出力
      result << "total #{File::Stat.new(dir).blocks}"
      result << format_entries(entries_in_dir.switch_sort(reverse: @filters.include?(:SORT_REVERSE)), dir).join("\n") unless entries_in_dir.size.zero?
      result.join("\n")
    end
    puts output.join("\n\n")
  end

  def format_entries(entries, base_dir = '')
    stats = entries.map do |entry|
      stat = File.lstat((Pathname.new(base_dir) + entry).to_s)
      mode_arr = conv_mode(stat.mode)
      {
        mode_str: mode_arr.join(''),
        xattr_flg: xattr?((Pathname.new(base_dir) + entry).to_s, mode_arr[0]) ? '@' : '',
        nlink: stat.nlink,
        # キャラクタデバイスの場合はデバイスタイプを表示
        file_size: /[bc]/.match?(mode_arr[0]) ? "0x#{stat.rdev.to_s(16)}" : stat.size.to_s,
        owner_group: "#{Etc.getpwuid(stat.uid).name}  #{Etc.getgrgid(stat.gid).name}",
        mtime: Time.at(stat.mtime).strftime('%_m %_d %H:%M').to_s,
        file_str: mode_arr[0] == 'l' ? "#{entry} -> #{File.readlink((Pathname.new(base_dir) + entry).to_s)}" : entry
      }
    end
    output_longformat(stats)
  end

  def output_longformat(stats)
    max_mode_digit = get_max_digit(stats.map { |e| e[:mode_str] })
    max_size_digit = get_max_digit(stats.map { |e| e[:file_size] })
    max_nlink_digit = get_max_digit(stats.map { |e| e[:nlink] })

    stats.map do |stat|
      mode_fmt_str = format("%-#{max_mode_digit}s", "#{stat[:mode_str]}#{stat[:xattr_flg]}")
      size_fmt_str = stat[:file_size].rjust(max_size_digit)
      nlink_fmt_str = format("%#{max_nlink_digit}d", stat[:nlink])
      # 出力フォーマット
      "#{mode_fmt_str}  #{nlink_fmt_str} #{stat[:owner_group]}  #{size_fmt_str} #{stat[:mtime]} #{stat[:file_str]}"
    end
  end

  def conv_mode(mode)
    mode_str = []
    _, type, special, owner, group, other = /(.{1,2})(.)(.)(.)(.)/.match(mode.to_s(8)).to_a
    _, setuid, setgid, sticky = /(.)(.)(.)/.match(format('%03d', special.to_i.to_s(2))).to_a
    mode_str << type.type_conv
    mode_str << (setuid == '1' ? special_filter(owner.mode_conv, 's') : owner.mode_conv)
    mode_str << (setgid == '1' ? special_filter(group.mode_conv, 's') : group.mode_conv)
    mode_str << (sticky == '1' ? special_filter(other.mode_conv, 't') : other.mode_conv)
    mode_str
  end

  def special_filter(mode_str, special_flag)
    case mode_str.match(/.$/)[0]
    when '-' then mode_str.sub(/.$/, special_flag.upcase)
    when 'x' then mode_str.sub(/.$/, special_flag.downcase)
    end
  end

  def get_max_digit(arr)
    # 文字列の最大桁数を取得する
    arr.map { |e| e.to_s.chars.size }.max
  end

  def xattr?(entry, file_type)
    return false unless ['-', 'd'].include?(file_type)

    io = IO.popen(['xattr', '-l', entry], 'r', err: open('/dev/null', 'w'))
    result = io.read
    io.close
    !result.chars.size.zero?
  end
end

main if __FILE__ == $PROGRAM_NAME
