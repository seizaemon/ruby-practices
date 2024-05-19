# frozen_string_literal: true

require 'io/console/size'

class Screen
  def initialize(stats_in_dir, options = {})
    @stats_in_dir = stats_in_dir

    @long_format = options[:long_format]
    @reverse = options[:reverse]
    @header = options[:header]

    _, @console_width = IO.console_size
  end

  def show
    output_blocks = []

    output_blocks << create_output_block_with_file_stats
    output_blocks << create_output_blocks_with_dir_stats

    puts output_blocks.reject(&:empty?).join("\n\n")
  end

  private

  def create_output_block_with_file_stats
    @long_format ? show_detail(@stats_in_dir['']) : show_normal(@stats_in_dir[''])
  end

  def create_output_blocks_with_dir_stats
    @stats_in_dir.except('').map do |dir_path, stats|
      blocks = []

      blocks << "#{dir_path}:" if @header
      blocks << "total #{stats.map(&:blocks).sum}" if @long_format
      blocks << (@long_format ? show_detail(stats, dir_path) : show_normal(stats, dir_path))

      blocks.join("\n")
    end
  end

  def show_normal(stats, base_path = '')
    name_max_length = stats.map { |stat| stat.path(base_path) }.map(&:length).max || 0

    column_count = count_columns(stats.length, name_max_length)
    row_count = column_count.zero? ? 0 : count_rows(column_count, stats.length)

    formatted_rows = Array.new(row_count) do |row_index|
      stats_in_row = Array.new(column_count) { |col_index| stats[row_index + row_count * col_index] }.compact
      stats_in_row.map { |stat| stat.path(base_path).ljust(name_max_length) }.join(' ')
    end

    formatted_rows.join("\n")
  end

  def show_detail(stats, base_path = '')
    stat_attrs = stats.map { |stat| format_stat_attr(stat, base_path) }
    max_lengths = get_max_lengths(stat_attrs)

    formatted_rows = stat_attrs.map { |attr| format_row_in_detail(attr, max_lengths) }

    formatted_rows.flatten.join("\n")
  end

  def count_columns(stats_length, max_length)
    column_count = ((@console_width - 1) / (max_length + 1)).to_i
    column_count > stats_length ? stats_length : column_count
  end

  def count_rows(column_count, stats_length)
    (stats_length.to_f / column_count).ceil
  end

  def format_stat_attr(stat, base_path)
    {
      type: stat.type,
      permission: stat.permission,
      nlink: stat.nlink.to_s,
      owner: stat.owner,
      group: stat.group,
      size: stat.blockdev? || stat.chardev? ? "0x#{stat.rdev_major}00000#{stat.rdev_minor}" : stat.size.to_s,
      ctime: stat.ctime.strftime('%_m %_d %H:%M'),
      filename: stat.symlink? && @long_format ? "#{stat.path(base_path)} -> #{stat.original}" : stat.path(base_path)
    }
  end

  def get_max_lengths(stat_attrs)
    {
      nlink: stat_attrs.map { |attr| attr[:nlink].to_s.length }.max,
      owner: stat_attrs.map { |attr| attr[:owner].length }.max,
      group: stat_attrs.map { |attr| attr[:group].length }.max,
      size: stat_attrs.map { |attr| attr[:size].length }.max,
    }
  end

  def format_row_in_detail(attr, widths)
    columns = []
    columns << "#{attr[:type]}#{attr[:permission]} "
    columns << attr[:nlink].ljust(widths[:nlink])
    columns << "#{attr[:owner].ljust(widths[:owner])} "
    columns << "#{attr[:group].ljust(widths[:group])} "
    columns << attr[:size].rjust(widths[:size])
    columns << attr[:ctime]
    columns << attr[:filename]

    columns.join(' ')
  end
end
