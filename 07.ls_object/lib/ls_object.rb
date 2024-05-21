# frozen_string_literal: true

require 'pathname'
require_relative 'ls_file_stat'
require_relative 'screen'

class LsObject
  def initialize(paths, options)
    @paths = paths.empty? ? ['.'] : paths
    @options = options
  end

  def main
    @options[:header] = !(@paths.length == 1 || @paths.empty?)

    @screen_src = { '' => [] }
    create_sorted_path_names(@paths).each do |path_name|
      stat = LsFileStat.new(path_name)
      if stat.file?
        @screen_src[''] << stat
      else
        @screen_src[path_name.to_s] = create_stats_in_directory(path_name)
      end
    end

    Screen.new(@screen_src, @options).show
  end

  private

  def create_stats_in_directory(base_path_name)
    file_paths = Dir.glob('*', (@options[:all_visible] ? File::FNM_DOTMATCH : 0), base: base_path_name.to_s)
    file_paths << '..' if @options[:all_visible]
    create_sorted_path_names(file_paths, base_path_name.to_s).map do |path_name|
      LsFileStat.new(path_name)
    end
  end

  def create_sorted_path_names(file_paths, base_path = '.')
    sorted_paths = @options[:reverse] ? file_paths.sort.reverse : file_paths.sort
    sorted_paths.map { |path| Pathname.new(base_path).join(path) }
  end
end
