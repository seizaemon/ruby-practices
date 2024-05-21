# frozen_string_literal: true

require 'io/console/size'

class DetailFormatter
  def initialize(stats, base_path = '')
    @stats = stats
    @base_path = base_path

    _, @console_width = IO.console_size
  end

  def write
    stat_attrs = @stats.map { |stat| format_stat_attr(stat, @base_path) }
    max_lengths = get_max_lengths(stat_attrs)

    formatted_rows = stat_attrs.map { |attr| format_row_in_detail(attr, max_lengths) }

    formatted_rows.flatten.join("\n")
  end

  private

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
      size: stat_attrs.map { |attr| attr[:size].length }.max
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
