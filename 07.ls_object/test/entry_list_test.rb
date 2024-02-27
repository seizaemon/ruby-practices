# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/entry_list'
require_relative '../lib/file_entry'
require_relative './work_dir'

class EntryListTest < Minitest::Test
  include WorkDir

  def ready_test_env(&block)
    with_work_dir do
      @test_files = %w[file2 file1 file3]
      @test_dirs = %w[dir2 dir1]
      system "touch #{@test_files.join(' ')} ; mkdir #{@test_dirs.join(' ')}"
      block.call
    end
  end

  # entriesはファイルの名前の辞書順にFileEntryオブジェクトの配列が返る
  def test_entries
    ready_test_env do
      entry_list = EntryList.new(@test_files)
      @test_files.sort.each_with_index do |file, i|
        assert_equal FileEntry.new(file), entry_list.entries[i]
      end
    end
  end

  # reverseフラグ付きの場合はファイル名が辞書と逆順の配列を返す
  def test_reverse
    ready_test_env do
      entry_list = EntryList.new(@test_files, reverse: true)
      @test_files.sort.reverse.each_with_index do |entry, i|
        assert_equal FileEntry.new(entry), entry_list.entries[i]
      end
    end
  end

  # filesはファイルの名前の配列が辞書順に返る
  def test_files
    ready_test_env do
      entry_list = EntryList.new(@test_files)
      assert_equal @test_files.sort, entry_list.files
    end
  end

  # reverseフラグがついた場合filesはファイルの名前の配列が辞書の逆順の配列が返る
  def test_files_with_reverse
    ready_test_env do
      entry_list = EntryList.new(@test_files, reverse: true)
      assert_equal @test_files.sort.reverse, entry_list.files
    end
  end

  # 存在しないファイルを指定した場合はnot_founds辞書順でファイル名が入る
  def test_not_founds
    entry_list = EntryList.new(%w[no_file2 no_file1])
    assert_equal %w[no_file1 no_file2], entry_list.not_founds
  end

  # dirsはディレクトリの名前が辞書順の配列が返る
  def test_dirs
    ready_test_env do
      entry_list = EntryList.new(@test_dirs)
      assert_equal @test_dirs.sort, entry_list.dirs
    end
  end

  # reverseつきのdirsはディレクトリの名前が辞書の逆順の配列が返る
  def test_dirs_with_reverse
    ready_test_env do
      entry_list = EntryList.new(@test_dirs, reverse: true)
      assert_equal @test_dirs.sort.reverse, entry_list.dirs
    end
  end

  # entriesが空の場合empty?はtrueを返す
  def test_empty
    ready_test_env do
      entry_list_empty = EntryList.new([])
      entry_list_not_empty = EntryList.new(@test_files)

      assert entry_list_empty.empty?
      assert_equal false, entry_list_not_empty.empty?
    end
  end

  # baseオプションはbaseで指定したディレクトリ内のentryを返す
  def test_base
    with_work_dir do
      system 'mkdir test_dir; touch test_dir/test_file2 test_dir/test_file1'
      entry_list = EntryList.new(%w[test_file2 test_file1], base: 'test_dir')
      assert_equal [FileEntry.new('test_dir/test_file1'), FileEntry.new('test_dir/test_file2')], entry_list.entries
    end
  end
end

class EntryListMaxCharTest < Minitest::Test
  include WorkDir

  # link_max_charはファイルのlink数の桁数を返す
  def test_nlink_max_char
    with_work_dir do
      system 'touch test_file1'
      20.times { |n| system "ln test_file1 test_link#{n}" }
      entry_list = EntryList.new(['test_file1'])
      assert_equal 2, entry_list.nlink_max_char
    end
  end

  # owner_max_charはファイルownerの文字数を返す
  def test_owner_max_char
    with_work_dir do
      system 'touch test_file1'
      r, w = IO.pipe
      system 'id -un', out: w
      w.close
      entry_list = EntryList.new(['test_file1'])
      assert_equal r.gets('').chomp.length, entry_list.owner_max_char
    end
  end

  # group_max_charはファイルownerの文字数を返す
  def test_group_max_char
    with_work_dir do
      system 'touch test_file1'
      r, w = IO.pipe
      system 'id -gn', out: w
      w.close
      entry_list = EntryList.new(['test_file1'])
      assert_equal r.gets('').chomp.length, entry_list.group_max_char
    end
  end

  def test_size_max_char
    with_work_dir do
      system 'touch test_file1 test_file2'
      system 'dd if=/dev/zero of=test_file1 bs=128 count=1'
      system 'dd if=/dev/zero of=test_file2 bs=50 count=1'
      entry_list = EntryList.new(%w[test_file1 test_file2])
      assert_equal 3, entry_list.size_max_char
    end
  end

  # update_time_max_charはファイル更新時間の文字列の最大文字列を返す
  def test_update_time_max_char
    with_work_dir do
      system 'touch test_file1'
      now = Time.now.strftime('%_m %_d %H:%M')
      entry_list = EntryList.new(['test_file1'])
      assert_equal now.length, entry_list.update_time_max_char
    end
  end

  def test_filename_max_char
    with_work_dir do
      system 'touch test_file1 test_long_file1'
      entry_list = EntryList.new(%w[test_file1 test_long_file1])
      assert_equal 'test_long_file1'.length, entry_list.filename_max_char
    end
  end
end
