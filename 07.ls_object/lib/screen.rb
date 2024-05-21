# frozen_string_literal: true

require_relative 'normal_formatter'
require_relative 'detail_formatter'

class Screen
  def initialize(stats_in_dir, options = {})
    @stats_in_dir = stats_in_dir

    @long_format = options[:long_format]
    @reverse = options[:reverse]
    @header = options[:header]
  end

  def show
    output_blocks = []

    output_blocks << create_output_block_with_file_stats
    output_blocks << create_output_blocks_with_dir_stats

    puts output_blocks.reject(&:empty?).join("\n\n")
  end

  private

  def create_output_block_with_file_stats
    @long_format ? DetailFormatter.new(@stats_in_dir['']).write : NormalFormatter.new(@stats_in_dir['']).write
  end

  def create_output_blocks_with_dir_stats
    @stats_in_dir.except('').map do |dir_path, stats|
      blocks = []

      blocks << "#{dir_path}:" if @header
      blocks << "total #{stats.map(&:blocks).sum}" if @long_format
      blocks << (@long_format ? DetailFormatter.new(stats, dir_path).write : NormalFormatter.new(stats, dir_path).write)

      blocks.join("\n")
    end
  end
end
