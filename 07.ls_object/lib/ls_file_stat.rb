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

  def initialize(file_pathname)
    @pathname = file_pathname
  end

  def path(base_path = '')
    @pathname.absolute? ? @pathname.to_s : @pathname.relative_path_from(base_path).to_s
  end

  def symlink?
    @pathname.lstat.symlink?
  end

  def file?
    @pathname.lstat.file?
  end

  def original
    readlink if @pathname.lstat.symlink?
  end

  def nlink
    @pathname.lstat.nlink
  end

  def size
    @pathname.lstat.size
  end

  def permission
    mode_octet = @pathname.lstat.mode.to_s(8)[-3..].chars
    convert_mode(mode_octet)
  end

  def owner
    Etc.getpwuid(@pathname.lstat.uid).name
  end

  def group
    Etc.getgrgid(@pathname.lstat.gid).name
  end

  def ctime
    @pathname.lstat.ctime
  end

  def type
    return 'l' if @pathname.lstat.symlink?
    return '-' if @pathname.lstat.file?
    return 'p' if @pathname.lstat.ftype == 'fifo'

    @pathname.lstat.ftype[0].downcase
  end

  def directory?
    @pathname.lstat.directory?
  end

  def blockdev?
    @pathname.lstat.blockdev?
  end

  def chardev?
    @pathname.lstat.chardev?
  end

  def blocks
    @pathname.lstat.blocks
  end

  private

  def readlink
    File.readlink(@pathname)
  end

  def convert_mode(mode_octet)
    owner_mode = @pathname.lstat.setuid? ? convert_setid(MODE_MAP[mode_octet[0]]) : MODE_MAP[mode_octet[0]]
    group_mode = @pathname.lstat.setgid? ? convert_setid(MODE_MAP[mode_octet[1]]) : MODE_MAP[mode_octet[1]]
    other_mode = @pathname.lstat.sticky? ? MODE_MAP[mode_octet[2]].gsub(/x$/, 't').gsub(/-$/, 'T') : MODE_MAP[mode_octet[2]]

    [owner_mode, group_mode, other_mode].join
  end

  def convert_setid(mode_str)
    mode_str.gsub(/x$/, 's').gsub(/-$/, 'S')
  end
end
