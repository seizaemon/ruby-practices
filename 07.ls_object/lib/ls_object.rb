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
    header = @paths.length > 1

    screen_src = { '' => [] }
    create_sorted_pathnames(@paths).each do |pathname|
      stat = LsFileStat.new(pathname)
      if stat.file?
        screen_src[''] << stat
      else
        screen_src[pathname.to_s] = create_stats_in_directory(pathname)
      end
    end

    puts Screen.show(screen_src, @options, header:)
  end

  private

  def create_stats_in_directory(base_pathname)
    flags = @options[:all_visible] ? File::FNM_DOTMATCH : 0
    file_paths = Dir.glob('*', flags, base: base_pathname.to_s)
    file_paths << '..' if @options[:all_visible]
    create_sorted_pathnames(file_paths, base_pathname.to_s).map do |pathname|
      LsFileStat.new(pathname)
    end
  end

  def create_sorted_pathnames(file_paths, base_path = '.')
    sorted_paths = @options[:reverse] ? file_paths.sort.reverse : file_paths.sort
    sorted_paths.map { |path| Pathname.new(base_path).join(path) }
  end
end
