# frozen_string_literal: true

require 'io/console/size'

class Screen
  def initialize(entry_list)
    @entry_list = entry_list
    _, @console_width = IO.console_size
  end

  def out
    return '' if @entry_list.empty?

    row_num = calc_row_num(@console_width)
    longest_name_length = @entry_list.filename_max_char

    # 先頭列のindexを先に決め、各行のindexを決定していく
    (0..row_num - 1).map do |r|
      row_indexes = (r..@entry_list.length - 1).step(row_num).to_a
      fmt = (["%-#{longest_name_length}s"] * row_indexes.length).join(' ')
      format fmt, *(row_indexes.map { |i| @entry_list.entries[i].name })
    end.join("\n")
  end

  def out_in_detail
    fmt = "%1s%8s  % #{@entry_list.nlink_max_char}s " \
      +"% #{@entry_list.owner_max_char}s  " \
      +"% #{@entry_list.group_max_char}s  " \
      +"% #{@entry_list.size_max_char}s " \
      +"% #{@entry_list.update_time_max_char}s " \
      +"%-#{@entry_list.filename_max_char}s"
    @entry_list.entries.map do |entry|
      format fmt, entry.type, entry.permission, entry.nlink, entry.owner, entry.group, entry.size, entry.update_time, entry.name
    end.join("\n")
  end

  private

  def calc_column_num(width)
    column = 1
    max_char_length = @entry_list.filename_max_char
    column += 1 until ((max_char_length + 1) * column + max_char_length) > width
    column
  end

  def calc_row_num(width)
    (@entry_list.length.to_f / calc_column_num(width)).ceil
  end
end
