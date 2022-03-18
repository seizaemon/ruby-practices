# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'stringio'

class TestTools
  attr_reader :test_dir

  def initialize
    @test_dir = Dir.mktmpdir
    @ascii_file_basename = 'test_file'
    @ja_file_basename = '日本語のファイル'
    @ascii_dir_basename = 'test_dir'
    @ja_dir_basename = '日本語のディレクトリ'
  end

  def create_tmp_files(num_of_files, sub_dir: nil, is_ja: false, is_hidden: false, perm: 0o644)
    raise ArgumentError, "テストディレクトリ外にファイルは作成できません: #{sub_dir}" unless include?(sub_dir) || sub_dir.nil?
    raise Errno::ENOENT, "テストディレクトリ内にディレクトリが存在しません: #{sub_dir}" unless sub_dir.nil? || File.directory?("#{@test_dir}/#{sub_dir}")

    prefix = is_hidden ? '.' : ''
    basename = is_ja ? @ja_file_basename : @ascii_file_basename
    create_tmp_files_common(num_of_files, "#{prefix}#{basename}", sub_dir_name: sub_dir, perm:)
  end

  def create_tmp_files_common(num_of_files, basename, perm: 0o644, sub_dir_name: nil)
    return unless num_of_files.positive?

    File.umask(0o000)
    (1..num_of_files).to_a.map do |n|
      file_name = sub_dir_name.nil? ? "#{basename}#{n}" : "#{sub_dir_name}/#{basename}#{n}"
      File.open("#{@test_dir}/#{file_name}", 'w', perm) {}
      Time.now.strftime('%_m %d %H:%M').to_s
    end
  end

  def create_tmp_dirs(num_of_dirs, sub_dir: nil, is_ja: false, is_hidden: false, perm: 0o777)
    raise ArgumentError, "テストディレクトリ外にファイルは作成できません: #{sub_dir}}" unless include?(sub_dir) || sub_dir.nil?
    raise Errno::ENOENT, "テストディレクトリ内にディレクトリが存在しません: #{sub_dir}" unless sub_dir.nil? || File.directory?("#{@test_dir}/#{sub_dir}")

    prefix = is_hidden ? '.' : ''
    basename = is_ja ? @ja_dir_basename : @ascii_dir_basename
    create_tmp_dirs_common(num_of_dirs, "#{prefix}#{basename}", sub_dir_name: sub_dir, perm:)
  end

  def create_tmp_dirs_common(num_of_dirs, basename, sub_dir_name: nil, perm: 0o777)
    return unless num_of_dirs.positive?

    File.umask(0o000)
    (1..num_of_dirs).map do |n|
      dir_name = sub_dir_name.nil? ? "#{basename}#{n}" : "#{sub_dir_name}/#{basename}#{n}"
      Dir.mkdir("#{@test_dir}/#{dir_name}", perm)
      Time.now.strftime('%_m %d %H:%M').to_s
    end
  end

  def include?(dir_name_input)
    # rootで指定したディレクトリにinputで指定したディレクトリが含まれるか（存在するかは関係なし）
    return true if dir_name_input.nil?

    input = File.absolute_path(dir_name_input, @test_dir)
    input.match(/^#{File.absolute_path(@test_dir)}/)
  end

  # テストディレクトリ削除（再帰的に全て削除）
  def cleanup
    FileUtils.remove_entry_secure @test_dir
  end

  # テストディレクトリ内のファイル・ディレクトリ削除
  def remove_entries(entries)
    entries.each do |entry|
      FileUtils.remove_entry_secure "#{@test_dir}/#{entry}"
    end
  end

  def capture_stdout(ls_instance)
    out = StringIO.new
    $stdout = out
    ls_instance.output
    out.string
  ensure
    $stdout = STDOUT
  end
end

class TestToolsLongFormat < TestTools
  def create_symlink(from, to)
    File.symlink(from, to)
    Time.now.strftime('%_m %d %H:%M').to_s
  end

  def make_fifo
    File.umask(0o000)
    File.mkfifo("#{@test_dir}/test_fifo")
    Time.now.strftime('%_m %d %H:%M').to_s
  end

  def ref_blk_file
    # ブロックデバイスの作成にはroot権限が必要なので、存在するブロックデバイスの名前を探して返す
    "brw-r-----  1 root  operator  0x1000000  3  4 16:55 /dev/disk0\n"
  end

  def ref_char_file
    # キャラクタデバイスの作成にはroot権限が必要なので、存在するキャラクタデバイスの名前を探して返す
    # /dev/nullはキャラクタデバイス
    "crw-rw-rw-  1 root  wheel  0x3000003  3  4 16:55 /dev/zero\n"
  end

  def ref_socket_file
    "srw-rw-rw-  1 root  daemon  0  3  4 16:55 /var/run/mDNSResponder\n"
  end

  def ref_xattr_file
    "-rw-r--r--@  1 root  daemon  3768  3 11 22:49 /var/run/utmpx\n"
  end

  def create_tmp_file_with_ctime(num_of_files, sub_dir: nil, is_ja: false, is_hidden: false, perm: 0o644)
    create_tmp_files(num_of_files, sub_dir:, is_ja:, is_hidden:, perm:)
  end

  def create_tmp_dir_with_ctime(num_of_dirs, sub_dir: nil, is_ja: false, is_hidden: false, perm: 0o777)
    create_tmp_dirs(num_of_dirs, sub_dir:, is_ja:, is_hidden:, perm:)
  end
end
