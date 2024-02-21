# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/entry_list'
require_relative '../lib/file_entry'
require_relative './work_dir'

class EntryListTest < Minitest::Test
  include WorkDir
  # 指定したディレクトリのファイル一覧とFileEntryオブジェクトを作成し辞書順に収める

  def setup
    @test_files = %w[file2 file1 file3]
    @hidden_files = %w[.file1 .file2]
    @test_dirs = %w[dir1 dir2]
    @hidden_dirs = %w[.dir1 .dir2]
  end

  # entriesはファイルの名前の辞書順にFileEntryオブジェクトの配列が返る
  def test_create
    with_work_dir do
      system "touch #{@test_files.join(' ')}"
      entry_list = EntryList.new(@test_files)
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
      entry_list = EntryList.new(%w[entry_a entry_b entry_c entry_d entry_e entry_f].shuffle)
      %w[entry_a entry_b entry_c entry_d entry_e entry_f].each_with_index do |entry, i|
        assert_equal FileEntry.new(entry), entry_list.entries[i]
      end
    end
  end

  # hiddenフラグをonにした場合entriesは隠しエントリの名前が辞書順の配列を返す
  # def test_create_with_hidden_entries
  #   with_work_dir do
  #     system "touch #{@hidden_files.join(' ')}"
  #     entry_list = EntryList.new(hidden: true)
  #     ['.', '..', @hidden_files].flatten.sort.each_with_index do |entry, i|
  #       assert_equal FileEntry.new(entry), entry_list.entries[i]
  #     end
  #   end
  # end

  # entriesは隠しエントリも種別関係なく名前が辞書順の配列を返す
  # def test_create_with_variable_hidden_entries
  #   with_work_dir do
  #     system 'touch .entry_c .entry_e'
  #     system 'mkdir .entry_b .entry_d'
  #     system 'mkfifo .entry_a .entry_f'
  #     entry_list = EntryList.new(hidden: true)
  #     %w[. .. .entry_a .entry_b .entry_c .entry_d .entry_e .entry_f].each_with_index do |entry, i|
  #       assert_equal FileEntry.new(entry), entry_list.entries[i]
  #     end
  #   end
  # end

  # reverseフラグ付きの場合はファイル名が辞書と逆順の配列を返す
  def test_reverse
    with_work_dir do
      system "touch #{@test_files.join(' ')}"
      entry_list = EntryList.new(@test_files, reverse: true)
      @test_files.sort.reverse.each_with_index do |entry, i|
        assert_equal FileEntry.new(entry), entry_list.entries[i]
      end
    end
  end

  # hidden, reverseフラグ付きの場合名前が辞書と逆順となった配列を返す
  # def test_reverse_with_hidden_entries
  #   with_work_dir do
  #     system "touch #{@test_files.join(' ')} #{@hidden_files.join(' ')}"
  #     entry_list = EntryList.new(hidden: true, reverse: true)
  #     ['.', '..', @test_files, @hidden_files].flatten.sort.reverse.each_with_index do |entry, i|
  #       assert_equal FileEntry.new(entry), entry_list.entries[i]
  #     end
  #   end
  # end

  # ディレクトリを指定した場合指定したディレクトリ配下のファイルを検索した配列を返す
  # def test_with_directory_parameter
  #   with_work_dir do
  #     files = @test_files.map { |file| "test_dir/#{file}" }
  #     system "mkdir test_dir; touch #{files.join(' ')}"
  #     entry_list = EntryList.new('test_dir')
  #     @test_files.sort.each_with_index do |entry, i|
  #       assert_equal FileEntry.new("test_dir/#{entry}"), entry_list.entries[i]
  #     end
  #   end
  # end

  # entriesが空の場合empty?はtrueを返す
  def test_empty
    system "touch #{@test_files.join(' ')}"
    entry_list_empty = EntryList.new([])
    entry_list_not_empty = EntryList.new(@test_files)

    assert entry_list_empty.empty?
    assert_equal false, entry_list_not_empty.empty?
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
      assert_equal r.gets.chomp.length, entry_list.owner_max_char
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
      assert_equal r.gets.chomp.length, entry_list.group_max_char
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

  # TODO: baseを指定した場合

end
