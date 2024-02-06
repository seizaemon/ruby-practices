# frozen_string_literal: true

require 'etc'
require 'time'
class FileEntry < File::Stat
  attr_reader :name

  def initialize(file_path)
    super
    @name = file_path
  end

  def permission
    mode_convert(mode.to_s(8).slice(3..7))
  end

  def owner
    Etc.getpwuid(uid).name
  end

  def group
    Etc.getgrgid(gid).name
  end

  def update_time
    Time.parse(atime.to_s)
  end

  def type
    type_convert(ftype)
  end

  private

  def mode_convert(mode_num)
    mode_map = {
      '0' => '---',
      '1' => '--x',
      '2' => '-w-',
      '3' => '-wx',
      '4' => 'r--',
      '5' => 'r-x',
      '6' => 'rw-',
      '7' => 'rwx'
    }
    mode_num.split('').map { |s| mode_map[s] }.join('')
  end

  def type_convert(type_str)
    type_map = {
      'fifo' => 'p', # FIFO
      'characterSpecial' => 'c', # Character Special
      'directory' => 'd', # Directory
      'blockSpecial' => 'b', # Block Special
      'file' => '-', # Regular file
      'link' => 'l', # Symbolic link
      'socket' => 's' # Socket
    }
    type_map[type_str]
  end
end
