# frozen_string_literal: true

require 'io/console/size'

class Screen
  def initialize(entry_list)
    @entry_list = entry_list
    _, @console_width = IO.console_size
  end

  def out
    return '' if @entry_list.entries.empty?

    screen_row = calc_row_num(@console_width)
    longest_name = @entry_list.filename_max_char

    # 先頭列のindexを先に決め、各行のindexを決定していく
    (0..screen_row - 1).map do |r|
      row_indexes = (r..@entry_list.length - 1).step(screen_row).to_a
      fmt = (["%-#{longest_name}s"] * row_indexes.length).join(' ')
      format fmt, *(row_indexes.map { |i| @entry_list.entries[i].name })
    end.join("\n")
  end

  private

  def calc_column_num(width)
    column = 1
    max_char = @entry_list.filename_max_char
    column += 1 until ((max_char + 1) * column + max_char) > width
    column
  end

  def calc_row_num(width)
    (@entry_list.length.to_f / calc_column_num(width)).ceil
  end
end
