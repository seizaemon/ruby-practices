# frozen_string_literal: true

require 'io/console/size'

class NormalFormatter
  def initialize(stats, base_path = '')
    @stats = stats
    @base_path = base_path

    _, @console_width = IO.console_size
  end

  def write
    name_max_length = @stats.map { |stat| stat.path(@base_path) }.map(&:length).max || 0

    column_count = count_columns(name_max_length)
    row_count = column_count.zero? ? 0 : count_rows(column_count, @stats.length)

    formatted_rows = Array.new(row_count) do |row_index|
      stats_in_row = Array.new(column_count) { |col_index| @stats[row_index + row_count * col_index] }.compact
      stats_in_row.map { |stat| stat.path(@base_path).ljust(name_max_length) }.join(' ')
    end

    formatted_rows.join("\n")
  end

  private

  def count_columns(max_length)
    column_count = ((@console_width - 1) / (max_length + 1)).to_i
    column_count > @stats.length ? @stats.length : column_count
  end

  def count_rows(column_count, stats_length)
    (stats_length.to_f / column_count).ceil
  end
end
