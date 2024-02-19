# frozen_string_literal: true

require 'etc'
require 'time'
class FileEntry < File::Stat
  attr_reader :name

  def initialize(file_path)
    super
    @name = File.basename(file_path)
  end

  def permission
    mode_to_s(mode.to_s(8).match(/.{4}$/)[0].chars)
  end

  def owner
    Etc.getpwuid(uid).name
  end

  def group
    Etc.getgrgid(gid).name
  end

  def update_time
    Time.parse(atime.to_s).strftime('%-m %-d %H:%M')
  end

  def type
    type_convert(ftype)
  end

  private

  def mode_to_s(mode_octet)
    mode_special = mode_octet.shift
    mode_main = mode_octet
    mode_convert(mode_main, mode_special)
  end

  def mode_convert(mode_octet_arr, special_octet)
    mode_map = {
      '0' => '---', '1' => '--x', '2' => '-w-',
      '3' => '-wx', '4' => 'r--', '5' => 'r-x',
      '6' => 'rw-', '7' => 'rwx'
    }
    mode_arr = []
    mode_arr << (special_octet == '4' ? mode_map[mode_octet_arr.shift].gsub(/x$/, 's').gsub(/-$/, 'S') : mode_map[mode_octet_arr.shift])
    mode_arr << (special_octet == '2' ? mode_map[mode_octet_arr.shift].gsub(/x$/, 's').gsub(/-$/, 'S') : mode_map[mode_octet_arr.shift])
    mode_arr << (special_octet == '1' ? mode_map[mode_octet_arr.shift].gsub(/x$/, 't').gsub(/-$/, 'T') : mode_map[mode_octet_arr.shift])
    mode_arr.join('')
  end

  def type_convert(type_str)
    return 'l' if FileTest.symlink?(@name)
    return '-' if type_str == 'file'

    type_str[0].downcase
  end
end
