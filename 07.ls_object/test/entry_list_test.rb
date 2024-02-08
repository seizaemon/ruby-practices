# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/entry_list'
require_relative '../lib/file_entry'
require_relative './work_dir'

class EntryListTest < Minitest::Test
  include WorkDir
  # 指定したディレクトリのファイル一覧とFileEntryオブジェクトを作成し辞書順に収める

  def setup
    @test_files = %w[file1 file2 file3]
    @hidden_files = %w[.file1 .file2]
    @test_dirs = %w[dir1 dir2]
    @hidden_dirs = %w[.dir1 .dir2]
  end

  # entriesはファイルの名前が辞書順の配列におさめる
  def test_create
    with_work_dir do
      system "touch #{@test_files.join(' ')}"
      entry_list = EntryList.new
      @test_files.sort.each_with_index do |file, i|
        assert_equal FileEntry.new(file), entry_list.entries[i]
      end
    end
  end

  # entriesはファイルの種別関係なく名前が辞書順の配列を返す
  def test_create_with_variable_entries
    with_work_dir do
      system 'touch entry_c entry_e'
      system 'mkdir entry_b entry_d'
      system 'mkfifo entry_a entry_f'
      entry_list = EntryList.new
      %w[entry_a entry_b entry_c entry_d entry_e entry_f].each_with_index do |entry, i|
        assert_equal FileEntry.new(entry), entry_list.entries[i]
      end
    end
  end

  # hiddenフラグをonにした場合entriesは隠しエントリの名前が辞書順の配列を返す
  def test_create_with_hidden_entries
    with_work_dir do
      system "touch #{@hidden_files.join(' ')}"
      entry_list = EntryList.new(hidden: true)
      ['.', '..', @hidden_files].flatten.sort.each_with_index do |entry, i|
        assert_equal FileEntry.new(entry), entry_list.entries[i]
      end
    end
  end

  # entriesは隠しエントリも種別関係なく名前が辞書順の配列を返す
  def test_create_with_variable_hidden_entries
    with_work_dir do
      system 'touch .entry_c .entry_e'
      system 'mkdir .entry_b .entry_d'
      system 'mkfifo .entry_a .entry_f'
      entry_list = EntryList.new(hidden: true)
      %w[. .. .entry_a .entry_b .entry_c .entry_d .entry_e .entry_f].each_with_index do |entry, i |
        assert_equal FileEntry.new(entry), entry_list.entries[i]
      end
    end
  end

  # reverse_entriesはファイル名が辞書と逆順の配列を返す
  def test_reverse
    with_work_dir do
      system "touch #{@test_files.join(' ')}"
      entry_list = EntryList.new(reverse: true)
      @test_files.sort.reverse.each_with_index do |entry, i|
        assert_equal FileEntry.new(entry), entry_list.entries[i]
      end
    end
  end

  # reverse_entriesは隠しエントリを優先してそれぞれ名前が辞書と逆順となった配列を返す
  def test_reverse_with_hidden_entries

  end
end
