# frozen_string_literal: true

require 'etc'
require 'time'
require 'pathname'

class LsFileStat
  DISABLE = '-'
  READ = 'r'
  WRITE = 'w'
  EXEC = 'x'
  MODE_MAP = {
    '0' => "#{DISABLE}#{DISABLE}#{DISABLE}",
    '1' => "#{DISABLE}#{DISABLE}#{EXEC}",
    '2' => "#{DISABLE}#{WRITE}#{DISABLE}",
    '3' => "#{DISABLE}#{WRITE}#{EXEC}",
    '4' => "#{READ}#{DISABLE}#{DISABLE}",
    '5' => "#{READ}#{DISABLE}#{EXEC}",
    '6' => "#{READ}#{WRITE}#{DISABLE}",
    '7' => "#{READ}#{WRITE}#{EXEC}"
  }.freeze

  def initialize(file_path)
    @stat = File.lstat file_path
    @path = file_path
  end

  # ok
  def name
    return "#{@path} -> #{readlink}" if @stat.symlink?

    @path
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
    convert_mode_str mode_octet
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

  # テストしてない？
  def self.bulk_create(paths, base: '', reverse: false)
    missing_paths = []
    stats = []

    paths_sorted = reverse ? paths.sort.reverse : paths.sort

    paths_sorted.each do |path|
      base_path = Pathname.new base
      stats << LsFileStat.new(base_path.join(path).to_s)
    rescue Errno::ENOENT
      missing_paths << path
    end

    # エラー時の表示は省略しました
    # エラー表示だけはreverseフラグにかかわらず辞書順
    # missing_paths.each { |path| warn "ls: #{path}: No such file or directory" }

    stats
  end

  private

  def readlink
    target_pathname = Pathname.new File.readlink(@path)
    current_pathname = Pathname.new '.'
    target_pathname.relative_path_from(current_pathname).to_s
  end

  def convert_mode_str(mode_octet)
    owner_mode_str = MODE_MAP[mode_octet[0]]
    group_mode_str = MODE_MAP[mode_octet[1]]
    other_mode_str = MODE_MAP[mode_octet[2]]

    owner_mode_str = convert_setid_str(owner_mode_str) if @stat.setuid?
    group_mode_str = convert_setid_str(group_mode_str) if @stat.setgid?
    other_mode_str = other_mode_str.gsub(/x$/, 't').gsub(/-$/, 'T') if @stat.sticky?

    [owner_mode_str, group_mode_str, other_mode_str].join('')
  end

  def convert_setid_str(mode_str)
    mode_str.gsub(/x$/, 's').gsub(/-$/, 'S')
  end
end
