# frozen_string_literal: true

require 'minitest/autorun'
require 'pathname'
require 'time'
require_relative '../lib/ls_file_stat'
require_relative 'work_dir'
require_relative 'create_test_file'

class LsFileStatTest < Minitest::Test
  include WorkDir
  include CreateTestFile

  # nameはファイル名を返す
  def test_name
    with_work_dir do
      system 'touch test_file'
      file_entry = LsFileStat.new('test_file')
      assert_equal 'test_file', file_entry.name
    end
  end

  # sizeはファイルサイズを返す
  def test_size
    with_work_dir do |work_dir|
      block_size = 1024
      count = 10
      system "dd if=/dev/zero of=#{work_dir}/test_file bs=#{block_size} count=#{count}"
      file_entry = LsFileStat.new('test_file')
      assert_equal block_size * count, file_entry.size
    end
  end

  # update_dateはlsのフォーマットに従ってファイル最新更新日を返す
  def test_update_time
    with_work_dir do
      file_name, = filename_with_owner_and_group
      updated = Time.now.strftime('%_m %_d %H:%M')
      file_entry = LsFileStat.new(file_name)
      assert_equal updated, file_entry.update_time
    end
  end

  # ownerはファイルの所属オーナーを帰す
  def test_owner
    with_work_dir do
      test_file_name, user, = filename_with_owner_and_group
      file_entry = LsFileStat.new(test_file_name)
      assert_equal user, file_entry.owner
    end
  end

  # groupはファイルの所属グループを帰す
  def test_group
    with_work_dir do
      test_file_name, _, group = filename_with_owner_and_group
      file_entry = LsFileStat.new(test_file_name)
      assert_equal group, file_entry.group
    end
  end

  # typeはファイルが通常の場合 - を返す
  def test_type_with_normal_file
    with_work_dir do
      test_file_name, = filename_with_owner_and_group
      file_entry = LsFileStat.new(test_file_name)
      assert_equal '-', file_entry.type
    end
  end

  # typeはファイルがsymlinkの場合 l を返す
  def test_type_with_link
    with_work_dir do
      system 'touch test_file ; ln -s test_file test_link'
      file_entry = LsFileStat.new('test_link')
      assert_equal 'l', file_entry.type
    end
  end

  # nlinkはファイルリンク数を返す
  def test_nlink
    with_work_dir do
      system 'mkdir test; touch test/test_file1'
      file_entry = LsFileStat.new('test')
      # ディレクトリ内のハードリンクの数は .と..とtest_file1で3つ
      assert_equal 3, file_entry.nlink
    end
  end

  # baseを指定した場合nameはファイル名のみが入る
  def test_base_dir
    with_work_dir do
      system 'mkdir test_dir; touch test_dir/test_file'
      file_entry = LsFileStat.new('test_dir/test_file')
      assert_equal 'test_file', file_entry.name
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
      test_entries = %w[test_file test_file2 test_file3].map do |file|
        LsFileStat.new(file)
      end
      %w[rwxrw-r-x r---w---x ---------].each_with_index do |mode_str, i|
        assert_equal mode_str, test_entries[i].permission
      end
    end
  end

  # setuidのファイルの場合
  def test_permission_with_setuid
    with_work_dir do
      create_various_type_of_file
      file_entry1 = LsFileStat.new('test_file4')
      file_entry2 = LsFileStat.new('test_file5')

      assert_equal 'rwsrwxrwx', file_entry1.permission
      assert_equal 'rwSrw-rw-', file_entry2.permission
    end
  end

  # setgidのファイルの場合
  def test_permission_with_setgid
    with_work_dir do
      create_various_type_of_file
      file_entry1 = LsFileStat.new('test_file6')
      file_entry2 = LsFileStat.new('test_file7')

      assert_equal 'rwxrwsrwx', file_entry1.permission
      assert_equal 'rw-rwSrw-', file_entry2.permission
    end
  end

  # sticky bitつきのファイルの場合
  def test_permission_with_sticky
    with_work_dir do
      system 'mkdir test_dir1; chmod 1777 test_dir1'
      system 'mkdir test_dir2; chmod 1666 test_dir2'
      file_entry1 = LsFileStat.new('test_dir1')
      file_entry2 = LsFileStat.new('test_dir2')

      assert_equal 'rwxrwxrwt', file_entry1.permission
      assert_equal 'rw-rw-rwT', file_entry2.permission
    end
  end
end
