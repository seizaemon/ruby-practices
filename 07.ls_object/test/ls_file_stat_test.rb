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

  # ctimeはlsのフォーマットに従ってファイル最新更新日時を返す
  def test_ctime
    with_work_dir do
      file_name, = filename_with_owner_and_group
      updated = Time.now.strftime('%_m %_d %H:%M')
      stat = LsFileStat.new(file_name)
      assert_equal updated, stat.ctime.strftime('%_m %_d %H:%M')
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

  # originalは対象がsymlinkの場合はオリジナルファイルのパスを付与して返す
  def test_original
    with_work_dir do
      system 'mkdir test_dir ; touch test_dir/test_file ;  ln -s test_dir/test_file test_link'
      stat_symlink = LsFileStat.new('test_link')
      stat_non_symlink = LsFileStat.new('test_dir/test_file')
      assert_equal 'test_dir/test_file', stat_symlink.original
      assert_nil stat_non_symlink.original
    end
  end

  # permissionはファイルパーミッションの文字列を返す
  def test_permission
    with_work_dir do
      system 'touch test_file; chmod 752 test_file'
      stat_mode_test = LsFileStat.new('test_file')
      assert_equal 'rwxr-x-w-', stat_mode_test.permission
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

  # typeは指定したファイル名がディレクトリの場合dを返す
  def test_type_with_directory
    with_work_dir do
      system 'mkdir test_dir'
      file_entry = LsFileStat.new('test_dir')
      assert_equal 'd', file_entry.type
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

class LsBulkCreateTest < Minitest::Test
  include WorkDir

  # bulk_createはファイルパスの配列をFile.lstatの配列に変換する
  def test_bulk_create
    with_work_dir do
      system 'touch test_file1 test_file2'
      stats = LsFileStat.bulk_create %w[test_file1 test_file2]
      test_stat1 = LsFileStat.new 'test_file1'
      test_stat2 = LsFileStat.new 'test_file2'
      assert stats, [test_stat1, test_stat2]
    end
  end
end
