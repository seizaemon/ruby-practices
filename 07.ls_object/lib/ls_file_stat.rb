# frozen_string_literal: true

require 'etc'
require 'time'
require 'pathname'

class LsFileStat < File::Stat
  NULL = '-'
  READ = 'r'
  WRITE = 'w'
  EXEC = 'x'

  def initialize(file_path)
    super
    @path = file_path
  end

  def name
    base = File.basename @path
    return "#{base} -> #{readlink}" if type == 'l'

    base
  end

  def permission
    mode_octet = mode.to_s(8)[-4..].chars
    mode_special = mode_octet[0]
    mode_main = mode_octet[1..3]
    convert_into_mode(mode_main, mode_special)
  end

  def owner
    Etc.getpwuid(uid).name
  end

  def group
    Etc.getgrgid(gid).name
  end

  def update_time
    Time.parse(atime.to_s).strftime('%_m %_d %H:%M')
  end

  def type
    convert_into_type(ftype)
  end

  private

  def readlink
    org_path = Pathname.new(File.readlink(@path))
    link_path = Pathname.new(@path)
    org_path.relative_path_from(link_path.dirname).to_s
  end

  def convert_into_mode(mode_octet, special_octet)
    mode_map = {
      '0' => "#{NULL}#{NULL}#{NULL}",
      '1' => "#{NULL}#{NULL}#{EXEC}",
      '2' => "#{NULL}#{WRITE}#{NULL}",
      '3' => "#{NULL}#{WRITE}#{EXEC}",
      '4' => "#{READ}#{NULL}#{NULL}",
      '5' => "#{READ}#{NULL}#{EXEC}",
      '6' => "#{READ}#{WRITE}#{NULL}",
      '7' => "#{READ}#{WRITE}#{EXEC}"
    }
    mode_arr = []
    mode_arr << (special_octet == '4' ? mode_map[mode_octet[0]].gsub(/x$/, 's').gsub(/-$/, 'S') : mode_map[mode_octet[0]])
    mode_arr << (special_octet == '2' ? mode_map[mode_octet[1]].gsub(/x$/, 's').gsub(/-$/, 'S') : mode_map[mode_octet[1]])
    mode_arr << (special_octet == '1' ? mode_map[mode_octet[2]].gsub(/x$/, 't').gsub(/-$/, 'T') : mode_map[mode_octet[2]])
    mode_arr.join
  end

  def convert_into_type(type_str)
    return 'l' if FileTest.symlink?(@path)
    return '-' if type_str == 'file'
    return 'p' if type_str == 'fifo'

    type_str[0].downcase
  end
end

class << LsFileStat
  def bulk_create(entries, base: '', reverse: false)
    files = []
    dirs = []
    no_existence = []

    entries_processed = reverse ? entries.reverse : entries.sort

    result = entries_processed.map do |entry|
      f = LsFileStat.new((Pathname(base) + entry).to_s)
      f.type == 'd' ? dirs << entry : files << entry
      f
    rescue Errno::ENOENT
      no_existence << entry
    end

    { stats: result, files:, dirs:, no_existence: }
  end
end
