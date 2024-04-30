# frozen_string_literal: true

require 'io/console/size'
require 'matrix'

class Screen
  def initialize(file_stats)
    @file_stats = file_stats
    _, @console_width = IO.console_size
  end

  # statsの配列から出力用マトリクスを作成して出力内容を整理する
  def out
    return if @file_stats.empty?

    max_filename_char_length = pick_max_width_filename
    max_column_length = calc_column_num(max_filename_char_length)
    max_row_length = calc_max_row_num(max_column_length)

    out = []
    # 行列の大きさを決め手列方向に@statsを並べる
    out_matrix = Matrix.build(max_row_length, max_column_length) { |row, col| @file_stats[row + max_row_length * col] }
    out_matrix.row_vectors.each do |row|
      out << row.to_a.map do |stat|
        format("%-#{max_filename_char_length}s", stat.nil? ? '' : stat.name)
      end.join(' ')
    end

    out.join("\n")
  end

  def out_in_detail(show_block_size: false)
    return if @file_stats.empty?

    width_formats = max_widths
    rows = []
    @file_stats.each do |stat|
      rows << stat_out_detail_template(stat, width_formats)
    end

    if show_block_size
      <<~TEXT
        total #{@file_stats.map(&:blocks).sum}
        #{rows.join("\n")}
      TEXT
    else
      rows.join("\n")
    end
  end

  private

  def stat_out_detail_template(stat, width_formats)
    output_parts = []
    output_parts << format('%<type>1s%<permission>8s ', type: stat.type, permission: stat.permission)
    output_parts << format("% #{width_formats[:nlink]}s", stat.nlink)
    output_parts << format("%-#{width_formats[:owner]}s ", stat.owner)
    output_parts << format("%-#{width_formats[:group]}s ", stat.group)
    output_parts << format("% #{width_formats[:size]}s", stat.size_in_ls_format)
    output_parts << format("% #{width_formats[:atime]}s", stat.atime_in_ls_format)
    output_parts << format("%-#{width_formats[:filename]}s", stat.name(show_link: true))

    output_parts.join(' ')
  end

  def calc_column_num(max_char_length)
    # コンソール幅と最長のファイル名から、ファイルの名前を全て並べられるファイルの最大個数を計算
    return 1 if max_char_length >= @console_width

    # (max_length + 1) * column_num + max_length < console_width となるconlumn_numの最大値を求める
    column_num = ((@console_width - max_char_length) / (max_char_length + 1)).to_i
    # statsの要素数が最大列に満たない場合はそのまま返す
    column_num > @file_stats.length ? @file_stats.length : column_num
  end

  def calc_max_row_num(column_num)
    (@file_stats.length.to_f / column_num).ceil
  end

  def max_widths
    {
      nlink: pick_max_width_nlink,
      owner: pick_max_width_owner,
      group: pick_max_width_group,
      size: pick_max_with_size,
      atime: pick_max_width_atime,
      filename: pick_max_width_filename
    }
  end

  def pick_max_width_nlink
    @file_stats.map { |stat| stat.nlink.to_s.length }.max
  end

  def pick_max_width_owner
    @file_stats.map { |stat| stat.owner.length }.max
  end

  def pick_max_width_group
    @file_stats.map { |stat| stat.group.length }.max
  end

  def pick_max_with_size
    @file_stats.map { |stat| stat.size_in_ls_format.length }.max
  end

  def pick_max_width_atime
    @file_stats.map { |stat| stat.atime_in_ls_format.length }.max
  end

  def pick_max_width_filename
    @file_stats.map { |stat| stat.name.length }.max
  end
end
