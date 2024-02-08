# frozen_string_literal: true

require 'minitest/autorun'
require 'pathname'
require 'time'
require_relative '../lib/file_entry'
require_relative './work_dir'

class FileEntryTest < Minitest::Test
  include WorkDir

  # nameはファイル名を返す
  def test_name
    with_work_dir do
      system 'touch test_file'
      file_entry = FileEntry.new('test_file')
      assert_equal 'test_file', file_entry.name
    end
  end

  # sizeはファイルサイズを返す
  def test_size
    with_work_dir do |work_dir|
      block_size = 1024
      count = 10
      # 1MBのファイルを作成
      system "dd if=/dev/zero of=#{work_dir}/test_file bs=#{block_size} count=#{count}"
      file_entry = FileEntry.new('test_file')
      assert_equal block_size * count, file_entry.size
    end
  end

  # permissionはファイルパーミッションを文字列表現で返す
  def test_permission
    with_work_dir do
      system 'touch test_file; chmod 765 test_file'
      file_entry = FileEntry.new('test_file')
      assert_equal 'rwxrw-r-x', file_entry.permission
    end
  end

  # update_dateはファイル最新更新日を返す
  # メソッド名もう少し考える
  def test_update_time
    with_work_dir do
      r, w = IO.pipe
      system 'touch test_file; LANG=C date', out: w
      w.close
      result = r.gets.to_s.chomp
      updated = result.nil? ? exit : Time.parse(result)
      file_entry = FileEntry.new('test_file')
      assert_equal updated, file_entry.update_time
    end
  end

  # ownerはファイルの所属オーナーを帰す
  def test_owner
    with_work_dir do
      system 'touch test_file'
      r, w = IO.pipe
      system 'id -un', out: w
      w.close
      file_entry = FileEntry.new('test_file')
      assert_equal r.gets.to_s.chomp, file_entry.owner
    end
  end

  # groupはファイルの所属グループを帰す
  def test_group
    with_work_dir do
      system 'touch test_file'
      r, w = IO.pipe
      system 'id -gn', out: w
      w.close
      file_entry = FileEntry.new('test_file')
      assert_equal r.gets.to_s.chomp, file_entry.group
    end
  end

  # typeはファイルタイプを一文字で返す
  def test_type
    with_work_dir do
      system 'touch test_normal_file'
      file_entry = FileEntry.new('test_normal_file')
      assert_equal '-', file_entry.type
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
