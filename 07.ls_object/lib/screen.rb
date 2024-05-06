# frozen_string_literal: true

require 'io/console/size'

class Screen
  def initialize(file_stats, options = {})
    @file_stats = file_stats

    @long_format = options[:long_format]
    @header = options[:header]

    _, @console_width = IO.console_size
  end

  def show
    return nil if @file_stats.empty?

    @long_format ? show_detail(@file_stats) : show_normal(@file_stats)
  end

  def recursive_show(base: nil)
    output_blocks = []
    output_blocks << "#{base}:" if @header
    output_blocks << "total #{@file_stats.map(&:blocks).sum}" if @long_format
    output_blocks << (@long_format ? show_detail(@file_stats) : show_normal(@file_stats)).to_s
    output_blocks.join("\n")
  end

  private

  def show_normal(stats)
    stat_attrs = stats.map { |stat| format_stat_attr(stat) }
    max_lengths = get_max_lengths(stat_attrs)

    column_count = count_columns(max_lengths[:filename])
    row_count = count_rows(column_count)

    formatted_rows = Array.new(row_count) do |row_index|
      stats_in_row = Array.new(column_count) { |col_index| stats[row_index + row_count * col_index] }.compact
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

  def count_columns(max_name_length)
    return 0 if max_name_length.zero?

    column_count = ((@console_width - 1) / (max_name_length + 1)).to_i
    column_count > @file_stats.length ? @file_stats.length : column_count
  end

  def count_rows(column_count)
    return 0 if column_count.zero?

    (@file_stats.length.to_f / column_count).ceil
  end

  def format_stat_attr(stat)
    {
      type: stat.type,
      permission: stat.permission,
      nlink: stat.nlink.to_s,
      owner: stat.owner,
      group: stat.group,
      size: stat.blockdev? || stat.chardev? ? "0x#{stat.rdev_major}00000#{stat.rdev_minor}" : stat.size.to_s,
      ctime: stat.ctime.strftime('%_m %_d %H:%M'),
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
      ctime: 11,
      filename: stat_attrs.map { |attr| attr[:name].length }.max
    }
  end

  def format_row_in_detail(attr, widths)
    output_parts = []
    output_parts << "#{attr[:type]}#{attr[:permission]} "
    output_parts << attr[:nlink].ljust(widths[:nlink])
    output_parts << "#{attr[:owner].ljust(widths[:owner])} "
    output_parts << "#{attr[:group].ljust(widths[:group])} "
    output_parts << attr[:size].rjust(widths[:size])
    output_parts << attr[:ctime].rjust(widths[:ctime])
    output_parts << attr[:name].ljust(widths[:filename])

    output_parts.join(' ')
  end
end
