# frozen_string_literal: true

require 'io/console/size'
require_relative 'entries_helper'

class Screen
  include EntriesHelper

  def initialize(entry_list)
    @entry_list = entry_list
    _, @console_width = IO.console_size
  end

  def out
    return '' if @entry_list.empty?

    row_num = calc_row_num(@console_width)
    longest_name_length = filename_max_char(@entry_list)

    # 先頭列のindexを先に決め、各行のindexを決定していく
    (0..row_num - 1).map do |r|
      row_indexes = (r..@entry_list.length - 1).step(row_num).to_a
      fmt = (["%-#{longest_name_length}s"] * row_indexes.length).join(' ')
      format fmt, *(row_indexes.map { |i| @entry_list[i].name })
    end.join("\n")
  end

  def out_in_detail
    # fmt = "%1s%8s  % #{@entry_list.nlink_max_char}s " \
    #   +"% #{owner_max_char(@entry_list)}s  " \
    #   +"% #{group_max_char(@entry_list)}s  " \
    #   +"% #{size_max_char(@entry_list)}s " \
    #   +"% #{update_time_max_char(@entry_list)}s " \
    #   +"%-#{filename_max_char(@entry_list)}s"

    nlink_max_length = nlink_max_char(@entry_list)
    owner_max_length = owner_max_char(@entry_list)
    group_max_length = group_max_char(@entry_list)
    file_size_max_length = size_max_char(@entry_list)
    update_time_max_length = update_time_max_char(@entry_list)
    filename_max_length = filename_max_char(@entry_list)
    # TODO: 複雑なformatからの脱却
    @entry_list.map do |entry|
      output = []
      output << format('%<type>1s%<permission>8s ', type: entry.type, permission: entry.permission)
      output << format("%<nlink> #{nlink_max_length}s", nlink: entry.nlink)
      output << format("%<owner> #{owner_max_length}s ", owner: entry.owner)
      output << format("%<group> #{group_max_length}s ", group: entry.group)
      output << format("%<size> #{file_size_max_length}s", size: entry.size)
      output << format("%<update_time> #{update_time_max_length}s", update_time: entry.update_time)
      output << format("%<name>-#{filename_max_length}s", name: entry.name)
      output.join(' ')
    end.join("\n")
  end

  private

  def calc_column_num(width)
    column = 1
    max_char_length = filename_max_char(@entry_list)
    column += 1 until ((max_char_length + 1) * column + max_char_length) > width
    column
  end

  def calc_row_num(width)
    (@entry_list.length.to_f / calc_column_num(width)).ceil
  end
end
