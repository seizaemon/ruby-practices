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
    '6' => "#{READ}#{WRITE}#{NULL}",
    '7' => "#{READ}#{WRITE}#{EXEC}"
  }.freeze

  def initialize(file_path)
    @stat = File::Stat.new file_path
  end

  def name
    return "#{@stat.name} -> #{readlink}" if @stat.symlink?

    @stat.name
  end

  def str_size
    return "0x#{@stat.rdev_major}00000#{@stat.rdev_minor}" if @stat.blockdev? || @stat.chardev?

    size.to_s
  end

  def permission
    mode_octet = @stat.mode.to_s(8)[-4..].chars
    convert_mode_str mode_octet
  end

  def owner
    Etc.getpwuid(uid).name
  end

  def group
    Etc.getgrgid(gid).name
  end

  def update_time
    Time.parse(@stat.atime.to_s).strftime('%_m %_d %H:%M')
  end

  def type
    return 'l' if @stat.symlink?
    return '-' if @stat.file?
    return 'p' if @stat.ftype == 'fifo'

    @stat.ftype.downcase
  end

  def self.bulk_create(paths, base: '', reverse: false)
    missing_paths = []
    stats = []

    paths_sorted = reverse ? paths.sort.reverse : paths.sort

    paths_sorted.each do |path|
      stats << LsFileStat.new(File.join(base, file_name))
    rescue Errno::ENOENT
      missing << path
    end

    # エラー時の表示は省略しました
    # エラー表示だけはreverseフラグにかかわらず辞書順
    # missing_paths.each { |path| warn "ls: #{path}: No such file or directory" }

    return stats
  end

  private

  def readlink
    # Pathnameの登場が唐突
    org_path = Pathname.new(File.readlink(@stat.name))
    org_path.relative_path_from(Pathname.new('.')).to_s
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
