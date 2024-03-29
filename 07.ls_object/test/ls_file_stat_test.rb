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

  # update_dateはlsのフォーマットに従ってファイル最新更新日を返す
  def test_update_time
    with_work_dir do
      file_name, = filename_with_owner_and_group
      updated = Time.now.strftime('%_m %_d %H:%M')
      file_entry = LsFileStat.new(file_name)
      assert_equal updated, file_entry.update_time
    end
  end

  # ownerはファイルの所属オーナーを返す
  def test_owner
    with_work_dir do
      test_file_name, user, = filename_with_owner_and_group
      file_entry = LsFileStat.new(test_file_name)
      assert_equal user, file_entry.owner
    end
  end

  # groupはファイルの所属グループを返す
  def test_group
    with_work_dir do
      test_file_name, _, group = filename_with_owner_and_group
      file_entry = LsFileStat.new(test_file_name)
      assert_equal group, file_entry.group
    end
  end

  # 通常ファイルの場合ファイルパスを返す
  def test_name_with_normal_file
    with_work_dir do
      # カレントディレクトリにあるファイルの場合
      test_file_name, = filename_with_owner_and_group
      entry1 = LsFileStat.new(test_file_name)
      assert_equal test_file_name, entry1.name

      # カレントにないファイルの場合
      system 'mkdir test_dir ; touch test_dir/test_file3'
      entry2 = LsFileStat.new('test_dir/test_file3')
      assert_equal 'test_dir/test_file3', entry2.name
    end
  end

  # リンクの場合ファイル名はオリジナルファイルのパスを付与して返す
  def test_name_with_link
    with_work_dir do
      system 'touch test_file ; ln -s test_file test_link'
      file_entry = LsFileStat.new('test_link')
      assert_equal 'test_link -> test_file', file_entry.name
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

  # sizeはファイルサイズを返す
  def test_size_with_normal_file
    with_work_dir do
      system 'touch test_file1 ; dd if=/dev/zero of=test_file1 bs=128 count=1'
      file_entry = LsFileStat.new('test_file1')
      assert_equal '128', file_entry.str_size
    end
  end

  # block fileとcharacter fileの場合、sizeはmajor numberを返す
  def test_size_with_special_file
    with_work_dir do
      character_entry = LsFileStat.new('/dev/null')
      block_entry = LsFileStat.new('/dev/disk0')
      assert_equal '0x1000000', block_entry.str_size
      assert_equal '0x3000002', character_entry.str_size
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
end

class LsFileStatTypeTest
  # typeはファイルがblock special fileの場合 b を返す
  def test_type_with_block_device
    file_entry = LsFileStat.new('/dev/disk0')
    assert_equal 'b', file_entry.type
  end

  # typeはファイルがcharacter special fileの場合 c を返す
  def test_type_with_character_device
    file_entry = LsFileStat.new('/dev/null')
    assert_equal 'c', file_entry.type
  end

  # typeはファイルがFIFOの場合 p を返す
  def test_type_with_fifo
    with_work_dir do
      system 'mkfifo test_fifo'
      file_entry = LsFileStat.new('test_fifo')
      assert_equal 'p', file_entry.type
    end
  end

  # typeはファイルがsocketの場合 s を返す
  def test_type_with_socket
    with_work_dir do
      s = UNIXServer.new('sock')
      file_entry = LsFileStat.new('sock')
      assert_equal 's', file_entry.type
      s.close
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
