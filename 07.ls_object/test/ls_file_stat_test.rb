# frozen_string_literal: true

require 'minitest/autorun'
require 'pathname'
require 'time'
require 'socket'
require_relative '../lib/ls_file_stat'
require_relative 'work_dir'
require_relative 'create_test_file'

class LsFileStatTest < Minitest::Test
  include WorkDir
  include CreateTestFile

  # atimeはlsのフォーマットに従ってファイル最新更新日を返す
  def test_atime
    with_work_dir do
      file_name, = filename_with_owner_and_group
      updated = Time.now.strftime('%_m %_d %H:%M')
      stat = LsFileStat.new(file_name)
      assert_equal updated, stat.atime_in_ls_format
    end
  end

  # ownerはファイルの所属オーナーを返す
  def test_owner
    with_work_dir do
      test_file_name, user, = filename_with_owner_and_group
      stat = LsFileStat.new(test_file_name)
      assert_equal user, stat.owner
    end
  end

  # groupはファイルの所属グループを返す
  def test_group
    with_work_dir do
      test_file_name, _, group = filename_with_owner_and_group
      stat = LsFileStat.new(test_file_name)
      assert_equal group, stat.group
    end
  end

  # 通常ファイルの場合ファイルパスを返す
  def test_name_with_normal_file
    with_work_dir do
      # カレントディレクトリにあるファイルの場合
      test_file_name, = filename_with_owner_and_group
      stat_current = LsFileStat.new test_file_name
      assert_equal test_file_name, stat_current.name

      # カレントにないファイルの場合
      system 'mkdir test_dir ; touch test_dir/test_file3'
      stat_not_current = LsFileStat.new('test_dir/test_file3')
      assert_equal 'test_dir/test_file3', stat_not_current.name
    end
  end

  # リンクの場合ファイル名はオリジナルファイルのパスを付与して返す
  def test_name_with_link
    with_work_dir do
      system 'touch test_file ; ln -s test_file test_link'
      stat = LsFileStat.new('test_link')
      assert_equal 'test_link -> test_file', stat.name
    end
  end

  # sizeはファイルサイズを返す
  def test_str_size_with_normal_file
    with_work_dir do
      system 'touch test_file1 ; dd if=/dev/zero of=test_file1 bs=128 count=1'
      stat = LsFileStat.new('test_file1')
      assert_equal '128', stat.size_in_ls_format
    end
  end

  # block fileとcharacter fileの場合、sizeはmajor numberを返す
  def test_str_size_with_special_file
    with_work_dir do
      char_dev_stat = LsFileStat.new('/dev/null')
      blk_dev_stat = LsFileStat.new('/dev/disk0')
      assert_equal '0x1000000', blk_dev_stat.size_in_ls_format
      assert_equal '0x3000002', char_dev_stat.size_in_ls_format
    end
  end

  # baseを指定した場合nameはファイル名のみが入る
  def test_base_dir
    with_work_dir do
      system 'mkdir test_dir; touch test_dir/test_file'
      stat = LsFileStat.new('test_dir/test_file')
      assert_equal 'test_dir/test_file', stat.name
    end
  end

  # nlinkはファイルリンク数を返す
  def test_nlink
    with_work_dir do
      system 'mkdir test; touch test/test_file1'
      stat = LsFileStat.new('test')
      # ディレクトリ内のハードリンクの数は .と..とtest_file1で3つ
      assert_equal 3, stat.nlink
    end
  end
end

class LsFileStatTypeTest
  # typeはFile.lstat.type.downcase以外のものをテスト

  # typeはファイルが通常の場合 - を返す
  def test_type_with_normal_file
    with_work_dir do
      test_file_name, = filename_with_owner_and_group
      stat = LsFileStat.new(test_file_name)
      assert_equal '-', stat.type
    end
  end

  # typeはファイルがsymlinkの場合 l を返す
  def test_type_with_link
    with_work_dir do
      system 'touch test_file ; ln -s test_file test_link'
      symlink_stat = LsFileStat.new 'test_link'
      assert_equal 'l', symlink_stat.type
    end
  end

  # typeはファイルがFIFOの場合 p を返す
  def test_type_with_fifo
    with_work_dir do
      system 'mkfifo test_fifo'
      file_entry = LsFileStat.new('test_fifo')
      assert_equal 'p', file_entry.type
    end
  end
end

class LsFileStatPermissionTest < Minitest::Test
  include WorkDir
  include CreateTestFile

  # permissionはファイルパーミッションを文字列表現で返す
  def test_permission
    with_work_dir do
      create_various_type_of_file
      normal_file_stats = %w[test_file test_file2 test_file3].map do |file|
        LsFileStat.new(file)
      end
      %w[rwxrw-r-x r---w---x ---------].each_with_index do |mode_str, i|
        assert_equal mode_str, normal_file_stats[i].permission
      end
    end
  end

  # setuidのファイルの場合
  def test_permission_with_setuid
    with_work_dir do
      create_various_type_of_file
      non_setuid_stat = LsFileStat.new('test_file4')
      setuid_stat = LsFileStat.new('test_file5')

      assert_equal 'rwsrwxrwx', non_setuid_stat.permission
      assert_equal 'rwSrw-rw-', setuid_stat.permission
    end
  end

  # setgidのファイルの場合
  def test_permission_with_setgid
    with_work_dir do
      create_various_type_of_file
      non_setgid_stat = LsFileStat.new('test_file6')
      setgid_stat = LsFileStat.new('test_file7')

      assert_equal 'rwxrwsrwx', non_setgid_stat.permission
      assert_equal 'rw-rwSrw-', setgid_stat.permission
    end
  end

  # sticky bitつきのファイルの場合
  def test_permission_with_sticky
    with_work_dir do
      system 'mkdir test_dir1; chmod 1777 test_dir1'
      system 'mkdir test_dir2; chmod 1666 test_dir2'
      non_sticky_stat = LsFileStat.new('test_dir1')
      sticky_stat = LsFileStat.new('test_dir2')

      assert_equal 'rwxrwxrwt', non_sticky_stat.permission
      assert_equal 'rw-rw-rwT', sticky_stat.permission
    end
  end
end
