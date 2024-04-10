# frozen_string_literal: true

require 'io/console/size'

class Screen
  def initialize(bulk_created_ls_file_stats)
    @file_stats = bulk_created_ls_file_stats
    _, @console_width = IO.console_size
  end

  def out
    return '' if @file_stats.empty?

    max_row_num = calc_max_row_num(@console_width)
    longest_name_length = filename_max_length

    # 各行の先頭列のindexを決め、各行の内容を決定していく
    (0..max_row_num - 1).map do |row_index|
      column_indexes = (row_index..@file_stats.length - 1).step(max_row_num).to_a
      fmt_in_row = (["%-#{longest_name_length}s"] * column_indexes.length).join(' ')
      format fmt_in_row, *(column_indexes.map { |i| @file_stats[i].name })
    end.join("\n")
  end

  def out_in_detail
    @file_stats.map do |file_stat|
      output = []
      output << format('%<type>1s%<permission>8s ', type: file_stat.type, permission: file_stat.permission)
      output << format("%<nlink> #{nlink_max_length}s", nlink: file_stat.nlink)
      output << format("%<owner> #{owner_max_length}s ", owner: file_stat.owner)
      output << format("%<group> #{group_max_length}s ", group: file_stat.group)
      output << format("%<size> #{size_max_length}s", size: file_stat.str_size)
      output << format("%<update_time> #{update_time_max_length}s", update_time: file_stat.update_time)
      output << format("%<name>-#{filename_max_length}s", name: file_stat.name)
      output.join(' ')
    end.join("\n")
  end

  private

  def calc_column_num(width)
    column = 1
    max_char_length = filename_max_length
    column += 1 until ((max_char_length + 1) * column + max_char_length) > width
    column
  end

  def calc_max_row_num(width)
    (@file_stats.length.to_f / calc_column_num(width)).ceil
  end

  def nlink_max_length
    max_str_length @file_stats.map(&:nlink)
  end

  def owner_max_length
    max_str_length @file_stats.map(&:owner)
  end

  def group_max_length
    max_str_length @file_stats.map(&:group)
  end

  def size_max_length
    max_str_length @file_stats.map(&:size)
  end

  def update_time_max_length
    max_str_length @file_stats.map(&:update_time)
  end

  def filename_max_length
    max_str_length @file_stats.map(&:name)
  end

  def max_str_length(list)
    list.map { |e| e.to_s.length }.max
  end
end
