# frozen_string_literal: true

require 'io/console/size'

class Screen
  def initialize(file_stats, options = {})
    @file_stats = file_stats

    @long_format = options[:long_format]
    @reverse = options[:reverse]
    @all_visible = options[:all_visible]
    @header = options[:header]

    _, @console_width = IO.console_size
  end

  def show_files
    return nil if @file_stats.empty?

    @long_format ? show_detail(@file_stats) : show_normal(@file_stats)
  end

  def recursive_show(base: nil)
    return nil if @file_stats.empty?

    output_blocks = []
    output_blocks << "#{base}:" if @header
    output_blocks << "total #{@file_stats.map(&:blocks).sum}" if @long_format
    output_blocks << "#{@file_stats.map(&:blocks).max} " if @long_format
    output_blocks << (@long_format ? show_detail(@file_stats) : show_normal(@file_stats)).to_s
    output_blocks.join("\n")
  end

  private

  def show_normal(stats)
    stat_attrs = stats.map { |stat| format_stat_attr(stat) }
    max_lengths = get_max_lengths(stat_attrs)

    num_of_columns = calc_num_of_columns(max_lengths[:filename])
    num_of_rows = calc_num_of_rows(num_of_columns)

    formatted_rows = Array.new(num_of_rows) do |row_index|
      stats_in_row = Array.new(num_of_columns) { |col_index| stats[row_index + num_of_rows * col_index] }
      stats_in_row.map { |stat| stat.name.ljust(max_lengths[:filename]) }.join(' ')
    end

    formatted_rows.join("\n")
  end

  def show_detail(stats)
    stat_attrs = stats.map { |stat| format_stat_attr(stat) }
    max_lengths = get_max_lengths(stat_attrs)

    formatted_rows = stat_attrs.map { |attr| format_row_in_detail(attr, max_lengths) }

    formatted_rows.join("\n")
  end

  def calc_num_of_columns(max_name_length)
    return 0 if max_name_length.zero?

    # 表示する列数の最大値は最長のファイル名をスペースで連結した結果がコンソール幅を超えない最大数と同じ
    column_num = ((@console_width - max_name_length) / (max_name_length + 1)).to_i
    column_num > @file_stats.length ? @file_stats.length : column_num
  end

  def calc_num_of_rows(column_num)
    return 0 if column_num.zero?

    (@file_stats.length.to_f / column_num).ceil
  end

  def format_stat_attr(stat)
    {
      type: stat.type,
      permission: stat.permission,
      nlink: stat.nlink,
      owner: stat.owner,
      group: stat.group,
      size: stat.blockdev? || stat.chardev? ? "0x#{stat.rdev_major}00000#{stat.rdev_minor}" : stat.size.to_s,
      atime: stat.atime.strftime('%_m %_d %H:%M'),
      name: stat.symlink? && @long_format ? "#{stat.name} -> #{stat.original}" : stat.name
    }
  end

  def get_max_lengths(stat_attrs)
    return Hash.new(0) if stat_attrs.empty?

    {
      nlink: stat_attrs.map { |attr| attr[:nlink].to_s.length }.max,
      owner: stat_attrs.map { |attr| attr[:owner].length }.max,
      group: stat_attrs.map { |attr| attr[:group].length }.max,
      size: stat_attrs.map { |attr| attr[:size].length }.max,
      atime: 11,
      filename: stat_attrs.map { |attr| attr[:name].length }.max
    }
  end

  def format_row_in_detail(attr, width_formats)
    output_parts = []
    output_parts << format('%<type>1s%<permission>8s ', type: attr[:type], permission: attr[:permission])
    output_parts << format("% #{width_formats[:nlink]}s", attr[:nlink])
    output_parts << format("%-#{width_formats[:owner]}s ", attr[:owner])
    output_parts << format("%-#{width_formats[:group]}s ", attr[:group])
    output_parts << format("% #{width_formats[:size]}s", attr[:size])
    output_parts << format("% #{width_formats[:atime]}s", attr[:atime])
    output_parts << format("%-#{width_formats[:filename]}s", attr[:name])

    output_parts.join(' ')
  end
end
