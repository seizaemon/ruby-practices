# frozen_string_literal: true

require 'io/console/size'
require_relative 'ls_file_stat'

class Screen
  def initialize(file_stats, options = {})
    @file_stats = file_stats

    @long_format = options[:long_format]
    @reverse = options[:reverse]
    @all_visible = options[:all_visible]
    @header = options[:header]

    _, @console_width = IO.console_size
  end

  def show
    if @long_format
      puts show_detail(@file_stats)
    else
      puts show_normal(@file_stats)
    end
  end

  def recursive_show
    output_blocks = @file_stats.map do |stat|
      file_names = Dir.glob('*', (@all_visible ? File::FNM_DOTMATCH : 0), base: stat.name)
      file_names << '..' if @all_visible

      output_block = ''
      Dir.chdir(stat.name) do
        recursive_stats = LsFileStat.bulk_create(file_names, reverse: @reverse)
        output_block = "#{stat.name}:\n" if @header
        output_block +=
          if @long_format
            <<~TEXT
              total #{@file_stats.map(&:blocks).sum}
              #{show_detail(recursive_stats)}
            TEXT
          else
            show_normal(recursive_stats)
          end
      end
      output_block
    end

    puts output_blocks.join("\n")
  end

  private

  def show_normal(stats)
    stat_attrs = stats.map { |stat| format_stat_attr(stat) }
    max_lengths = get_max_lengths(stat_attrs)

    num_of_columns = num_of_columns > stats.length ? stats.length : ((@console_width - max_lengths[:filename]) / (max_lengths[:filename] + 1)).to_i
    num_of_rows = calc_row_length(num_of_columns)

    output_rows = Array.new(num_of_rows) do |row_index|
      stats_in_row = Array.new(num_of_columns) { |col| stats[row_index + num_of_rows * col] }
      stats_in_row.map { |stat| stat.name.ljust(max_lengths[:filename]) }.join(' ')
    end

    output_rows.join("\n")
  end

  def show_detail(stats)
    stat_attrs = stats.map { |stat| format_stat_attr(stat) }
    max_lengths = get_max_lengths(stat_attrs)

    output_rows = stat_attrs.map { |attr| create_output_row_in_detail(attr, max_lengths) }

    output_rows.join("\n")
  end

  def calc_row_length(column_length)
    return 0 if column_length.zero?

    (@file_stats.length.to_f / column_length).ceil
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

  def create_output_row_in_detail(attr, width_formats)
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
