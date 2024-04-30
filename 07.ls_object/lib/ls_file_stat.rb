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

  def initialize(file_path)
    @stat = File.lstat file_path
    @path = file_path
  end

  def self.bulk_create(paths, base: '', reverse: false)
    paths_sorted = reverse ? paths.sort.reverse : paths.sort

    paths_sorted.map do |path|
      target_path = Pathname.new(path)
      if target_path.absolute?
        LsFileStat.new(path)
      else
        base_path = Pathname.new(base)
        LsFileStat.new(base_path.join(path).to_s)
      end
    end
  end

  def name(show_link: false)
    @stat.symlink? && show_link ? "#{@path} -> #{readlink}" : @path
  end

  def nlink
    @stat.nlink
  end

  def size_in_ls_format
    return "0x#{@stat.rdev_major}00000#{@stat.rdev_minor}" if @stat.blockdev? || @stat.chardev?

    @stat.size.to_s
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

  def atime_in_ls_format
    @stat.atime.strftime('%_m %_d %H:%M')
  end

  def type
    return 'l' if @stat.symlink?
    return '-' if @stat.file?
    return 'p' if @stat.ftype == 'fifo'

    @stat.ftype[0].downcase
  end

  def file?
    @stat.file?
  end

  def directory?
    @stat.directory?
  end

  def blocks
    @stat.blocks
  end

  private

  def readlink
    target_pathname = Pathname.new File.readlink(@path)
    current_pathname = Pathname.new('.')
    target_pathname.relative_path_from(current_pathname).to_s
  end

  def convert_mode(mode_octet)
    owner_mode = @stat.setuid? ? convert_setid(MODE_MAP[mode_octet[0]]) : MODE_MAP[mode_octet[0]]
    group_mode = @stat.setuid? ? convert_setid(MODE_MAP[mode_octet[1]]) : MODE_MAP[mode_octet[1]]
    other_mode = @stat.sticky? ? MODE_MAP[mode_octet[2]].gsub(/x$/, 't').gsub(/-$/, 'T') : MODE_MAP[mode_octet[2]]

    [owner_mode, group_mode, other_mode].join
  end

  def convert_setid(mode_str)
    mode_str.gsub(/x$/, 's').gsub(/-$/, 'S')
  end
end
