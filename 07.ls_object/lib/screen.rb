# frozen_string_literal: true

require_relative 'normal_formatter'
require_relative 'detail_formatter'

class Screen
  def self.show(ls_file_stats, options = {}, header: false)
    new(ls_file_stats, options, header:).show
  end

  def initialize(ls_file_stats, options = {}, header: false)
    @stats = ls_file_stats

    @long_format = options[:long_format]
    @reverse = options[:reverse]
    @header = header
  end

  def show
    output_blocks = []

    output_blocks << create_output_block_with_file_stats
    output_blocks << create_output_blocks_with_dir_stats

    output_blocks.reject(&:empty?).join("\n\n").encode('UTF-8')
  end

  private

  def create_output_block_with_file_stats
    formatter_factory.new(@stats['']).write
  end

  def create_output_blocks_with_dir_stats
    @stats.except('').map do |dir_path, stat|
      blocks = []

      blocks << "#{dir_path}:" if @header
      blocks << formatter_factory.new(stat, dir_path).write

      blocks.join("\n")
    end
  end

  def formatter_factory
    @long_format ? DetailFormatter : NormalFormatter
  end

end
