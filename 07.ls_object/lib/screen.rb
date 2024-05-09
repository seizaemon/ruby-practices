# frozen_string_literal: true

require 'io/console/size'

class Screen
  def initialize(src_data, options = {})
    @src_data = src_data

    @long_format = options[:long_format]
    @reverse = options[:reverse]
    @header = options[:header]

    _, @console_width = IO.console_size
  end

  def show
    output_blocks = []

    output_blocks << create_output_block_with_file_stats

    dir_src_data = @src_data.except('')
    dir_src_data_sorted = sort_src_data(dir_src_data)
    output_blocks << create_output_blocks_with_dir_stats(dir_src_data_sorted, header: @header)

    puts output_blocks.reject(&:empty?).join("\n\n")
  end

  private

  def sort_src_data(src_data)
    if @reverse
      key_reversed = src_data.sort.reverse.to_h
      key_reversed.transform_values { |stats| stats.sort_by(&:name).reverse }
    else
      key_sorted = src_data.sort.to_h
      key_sorted.transform_values { |stats| stats.sort_by(&:name) }
    end
  end

  def create_output_block_with_file_stats
    file_stats = @reverse ? @src_data[''].sort_by(&:name).reverse : @src_data[''].sort_by(&:name)
    @long_format ? show_detail(file_stats) : show_normal(file_stats)
  end

  def create_output_blocks_with_dir_stats(src_data, header: true)
    src_data.map do |dir_name, stats|
      block = []

      block << "#{dir_name}:" if header
      block << "total #{stats.map(&:blocks).sum}" if @long_format

      block << (@long_format ? show_detail(stats) : show_normal(stats))

      block.join("\n")
    end
  end

  def show_normal(stats)
    stat_attrs = stats.map { |stat| format_stat_attr(stat) }
    max_lengths = get_max_lengths(stat_attrs)

    column_count = count_columns(stats.length, max_lengths)
    row_count = count_rows(column_count, stats.length)

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

  def count_columns(stats_length, max_lengths )
    column_count = ((@console_width - 1) / (max_lengths[:filename] + 1)).to_i
    column_count > stats_length ? stats_length : column_count
  end

  def count_rows(column_count, stats_length)
    return 0 if stats_length.zero?

    (stats_length.to_f / column_count).ceil
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
      filename: stat.symlink? && @long_format ? "#{stat.name} -> #{stat.original}" : stat.name
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
      filename: stat_attrs.map { |attr| attr[:filename].length }.max
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
    output_parts << attr[:filename].ljust(widths[:filename])

    output_parts.join(' ')
  end
end
