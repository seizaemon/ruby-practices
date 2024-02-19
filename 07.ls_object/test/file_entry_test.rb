# frozen_string_literal: true

require 'minitest/autorun'
require 'pathname'
require 'time'
require_relative '../lib/file_entry'
require_relative './work_dir'

class FileEntryTest < Minitest::Test
  include WorkDir

  def filename_owner_and_group
    system 'touch test_file'
    ['id -un', 'id -gn'].map do |cmd|
      element = ''
      IO.pipe do |r, w|
        system cmd, out: w
        element = r.gets.chomp
      end
      element
    end.push('test_file')
  end

  def create_various_type_of_file
    system 'touch test_file ; chmod 765 test_file ; touch test_file2 ; chmod 421 test_file2 ; touch test_file3 ; chmod 000 test_file3'
    system 'touch test_file4 ; chmod 4777 test_file4 ; touch test_file5 ; chmod 4666 test_file5'
    system 'touch test_file6 ; chmod 2777 test_file6 ; touch test_file7 ; chmod 2666 test_file7'
  end

  # nameはファイル名を返す
  def test_name
    with_work_dir do
      test_file_name, = filename_owner_and_group
      file_entry = FileEntry.new(test_file_name)
      assert_equal 'test_file', file_entry.name
    end
  end

  # sizeはファイルサイズを返す
  def test_size
    with_work_dir do |work_dir|
      # 1MBのファイルを作成
      system "dd if=/dev/zero of=#{work_dir}/test_file bs=1024 count=10"
      file_entry = FileEntry.new('test_file')
      assert_equal block_size * count, file_entry.size
    end
  end

  # permissionはファイルパーミッションを文字列表現で返す
  def test_permission
    with_work_dir do
      create_various_type_of_file
      test_entries = %w[test_file test_file2 test_file3].map do |file|
        FileEntry.new(file)
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
      file_entry1 = FileEntry.new('test_file4')
      file_entry2 = FileEntry.new('test_file5')

      assert_equal 'rwsrwxrwx', file_entry1.permission
      assert_equal 'rwSrw-rw-', file_entry2.permission
    end
  end

  # setgidのファイルの場合
  def test_permission_with_setgid
    with_work_dir do
      create_various_type_of_file
      file_entry1 = FileEntry.new('test_file6')
      file_entry2 = FileEntry.new('test_file7')

      assert_equal 'rwxrwsrwx', file_entry1.permission
      assert_equal 'rw-rwSrw-', file_entry2.permission
    end
  end

  # sticky bitつきのファイルの場合
  def test_permission_with_sticky
    with_work_dir do
      system 'mkdir test_dir1; chmod 1777 test_dir1'
      system 'mkdir test_dir2; chmod 1666 test_dir2'
      file_entry1 = FileEntry.new('test_dir1')
      file_entry2 = FileEntry.new('test_dir2')

      assert_equal 'rwxrwxrwt', file_entry1.permission
      assert_equal 'rw-rw-rwT', file_entry2.permission
    end
  end

  # update_dateはlsのフォーマットに従ってファイル最新更新日を返す
  # メソッド名もう少し考える
  def test_update_time
    with_work_dir do
      file_name, = filename_owner_and_group
      updated = Time.now.strftime('%-m %-d %H:%M')
      file_entry = FileEntry.new(file_name)
      assert_equal updated, file_entry.update_time
    end
  end

  # ownerはファイルの所属オーナーを帰す
  def test_owner
    with_work_dir do
      test_file_name, user, = filename_owner_and_group
      file_entry = FileEntry.new(test_file_name)
      assert_equal user, file_entry.owner
    end
  end

  # groupはファイルの所属グループを帰す
  def test_group
    with_work_dir do
      test_file_name, _, group = filename_owner_and_group
      file_entry = FileEntry.new(test_file_name)
      assert_equal group, file_entry.group
    end
  end

  # typeはファイルが通常の場合 - を返す
  def test_type_with_normal_file
    with_work_dir do
      test_file_name, = filename_owner_and_group
      file_entry = FileEntry.new(test_file_name)
      assert_equal '-', file_entry.type
    end
  end

  # typeはファイルがsymlinkの場合 l を返す
  def test_type_with_link
    with_work_dir do
      system 'touch test_file ; ln -s test_file test_link'
      file_entry = FileEntry.new('test_link')
      assert_equal 'l', file_entry.type
    end
  end

  # nlinkはファイルリンク数を返す
  def test_nlink
    with_work_dir do
      system 'mkdir test; touch test/test_file1'
      file_entry = FileEntry.new('test')
      # ディレクトリ内のハードリンクの数は .と..とtest_file1で3つ
      assert_equal 3, file_entry.nlink
    end
  end
end
