# frozen_string_literal: true

require 'etc'
require 'time'
require 'pathname'

class LsFileStat
  MODE_MAP = {
    '0' => '---',
    '1' => '--x',
    '2' => '-w-',
    '3' => '-wx',
    '4' => 'r--',
    '5' => 'r-x',
    '6' => 'rw-',
    '7' => 'rwx'
  }.freeze

  def initialize(file_path, base_path = '')
    @path = Pathname.new(file_path)
    @base_path = Pathname.new(base_path)

    @stat = File.lstat @base_path.join(@path).to_s
  end

  def path
    @path.to_s
  end

  def symlink?
    @stat.symlink?
  end

  def file?
    @stat.file?
  end

  def original
    readlink if @stat.symlink?
  end

  def nlink
    @stat.nlink
  end

  def size
    @stat.size
  end

  def permission
    mode_octet = @stat.mode.to_s(8)[-3..].chars
    convert_mode(mode_octet)
  end

  def owner
    Etc.getpwuid(@stat.uid).name
  end

  def group
    Etc.getgrgid(@stat.gid).name
  end

  def ctime
    @stat.ctime
  end

  def type
    return 'l' if @stat.symlink?
    return '-' if @stat.file?
    return 'p' if @stat.ftype == 'fifo'

    @stat.ftype[0].downcase
  end

  def directory?
    @stat.directory?
  end

  def blockdev?
    @stat.blockdev?
  end

  def chardev?
    @stat.chardev?
  end

  def blocks
    @stat.blocks
  end

  private

  def readlink
    File.readlink(@base_path.join(@path).to_s)
  end

  def convert_mode(mode_octet)
    owner_mode = @stat.setuid? ? convert_setid(MODE_MAP[mode_octet[0]]) : MODE_MAP[mode_octet[0]]
    group_mode = @stat.setgid? ? convert_setid(MODE_MAP[mode_octet[1]]) : MODE_MAP[mode_octet[1]]
    other_mode = @stat.sticky? ? MODE_MAP[mode_octet[2]].gsub(/x$/, 't').gsub(/-$/, 'T') : MODE_MAP[mode_octet[2]]

    [owner_mode, group_mode, other_mode].join
  end

  def convert_setid(mode_str)
    mode_str.gsub(/x$/, 's').gsub(/-$/, 'S')
  end
end
