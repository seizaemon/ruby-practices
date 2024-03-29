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
    longest_name_length = filename_max_length(@entry_list)

    # 先頭列のindexを先に決め、各行のindexを決定していく
    (0..row_num - 1).map do |r|
      row_indexes = (r..@entry_list.length - 1).step(row_num).to_a
      fmt = (["%-#{longest_name_length}s"] * row_indexes.length).join(' ')
      format fmt, *(row_indexes.map { |i| @entry_list[i].name })
    end.join("\n")
  end

  def out_in_detail
    nlink_width = nlink_max_length(@entry_list)
    owner_width = owner_max_length(@entry_list)
    group_width = group_max_length(@entry_list)
    file_size_width = size_max_length(@entry_list)
    update_time_width = update_time_max_length(@entry_list)
    filename_width = filename_max_length(@entry_list)

    @entry_list.map do |entry|
      output = []
      output << format('%<type>1s%<permission>8s ', type: entry.type, permission: entry.permission)
      output << format("%<nlink> #{nlink_width}s", nlink: entry.nlink)
      output << format("%<owner> #{owner_width}s ", owner: entry.owner)
      output << format("%<group> #{group_width}s ", group: entry.group)
      output << format("%<size> #{file_size_width}s", size: entry.str_size)
      output << format("%<update_time> #{update_time_width}s", update_time: entry.update_time)
      output << format("%<name>-#{filename_width}s", name: entry.name)
      output.join(' ')
    end.join("\n")
  end

  private

  def calc_column_num(width)
    column = 1
    max_char_length = filename_max_length(@entry_list)
    column += 1 until ((max_char_length + 1) * column + max_char_length) > width
    column
  end

  def calc_row_num(width)
    (@entry_list.length.to_f / calc_column_num(width)).ceil
  end

  def nlink_max_length(entries)
    entries.map { |entry| entry.nlink.to_s.length }.max
  end

  def owner_max_length(entries)
    entries.map { |entry| entry.owner.length }.max
  end

  def group_max_length(entries)
    entries.map { |entry| entry.group.length }.max
  end

  def size_max_length(entries)
    entries.map { |entry| entry.size.to_s.length }.max
  end

  def update_time_max_length(entries)
    entries.map { |entry| entry.update_time.length }.max
  end

  def filename_max_length(entries)
    entries.map { |entry| entry.name.length }.max
  end
end
