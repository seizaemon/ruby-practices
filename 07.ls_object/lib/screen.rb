# frozen_string_literal: true

require_relative 'normal_formatter'
require_relative 'detail_formatter'

class Screen
  def self.show(ls_file_stats, options = {})
    new(ls_file_stats, options).show
  end

  def initialize(ls_file_stats, options = {})
    @ls_file_stats = ls_file_stats

    @long_format = options[:long_format]
    @reverse = options[:reverse]
    @header = options[:header]
  end

  def show
    output_blocks = []

    output_blocks << create_output_block_with_file_stats
    output_blocks << create_output_blocks_with_dir_stats

    output_blocks.reject(&:empty?).join("\n\n")
  end

  private

  def create_output_block_with_file_stats
    formatter_factory.new(@ls_file_stats['']).write
  end

  def create_output_blocks_with_dir_stats
    @ls_file_stats.except('').map do |dir_path, stats|
      blocks = []

      blocks << "#{dir_path}:" if @header
      blocks << formatter_factory.new(stats, dir_path).write

      blocks.join("\n")
    end
  end

  def formatter_factory
    @long_format ? DetailFormatter : NormalFormatter
  end

end
