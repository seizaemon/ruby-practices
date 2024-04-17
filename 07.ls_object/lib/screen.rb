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
    max_filename_width = pick_max_width_filename

    # 各行の先頭列のindexから各行の内容を決定していく
    (0..max_row_num - 1).each do |row_index|
      start_col_index = row_index
      end_col_index = @file_stats.length - 1
      column_indexes_in_row = (start_col_index..end_col_index).step(max_row_num).to_a

      output_fmt_in_row = (["%-#{max_filename_width}s"] * column_indexes_in_row.length).join(' ')
      output_columns = column_indexes_in_row.map { |i| @file_stats[i].name }

      puts(format output_fmt_in_row, *output_columns)
    end
  end

  def out_in_detail
    @file_stats.each do |stat|
      output_parts = []
      output_parts << format('%1s%8s ', stat.type, stat.permission)
      output_parts << format("% #{pick_max_width_nlink}s", stat.nlink)
      output_parts << format("% #{pick_max_width_owner}s ", stat.owner)
      output_parts << format("% #{pick_max_width_group}s ", stat.group)
      output_parts << format("% #{pick_max_with_size}s", stat.str_size)
      output_parts << format("% #{pick_max_width_update_time}s", stat.update_time)
      output_parts << format("%-#{pick_max_width_filename}s", stat.name)

      puts output_parts.join(' ')
    end
  end

  private

  def calc_column_num(width)
    max_length = pick_max_width_filename
    # コンソール幅と最長のファイル名から、ファイルの名前を全て並べられるファイルの最大個数を計算
    ((width - max_length) / (max_length + 1)).to_f
  end

  def calc_max_row_num(width)
    (@file_stats.length.to_f / calc_column_num(width)).ceil
  end

  def pick_max_width_nlink
    pick_max_str_len @file_stats.map(&:nlink)
  end

  def pick_max_width_owner
    pick_max_str_len @file_stats.map(&:owner)
  end

  def pick_max_width_group
    pick_max_str_len @file_stats.map(&:group)
  end

  def pick_max_with_size
    pick_max_str_len @file_stats.map(&:size)
  end

  def pick_max_width_update_time
    pick_max_str_len @file_stats.map(&:update_time)
  end

  def pick_max_width_filename
    pick_max_str_len @file_stats.map(&:name)
  end

  def pick_max_str_len(string_list)
    string_list.map { |e| e.to_s.length }.max
  end
end
