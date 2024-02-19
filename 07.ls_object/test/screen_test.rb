# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/screen'
require_relative '../lib/entry_list'
require_relative './work_dir'
require 'io/console/size'

class ScreenTest < Minitest::Test
  include WorkDir
  # テスト用のファイル名は11文字固定
  FILENAME_CHAR_COUNT = 11
  def setup
    _, @console_width = IO.console_size
  end

  def create_test_files(max_file_num)
    max_file_num.times do |n|
      suffix = format('%02d', n)
      File.open("test_file#{suffix}", 'w', 0o755) {}
    end
  end

  # ファイルが少ない場合ファイル一覧は横にならべられる
  def test_out_with_few_entries
    expected = <<~TEXT
      test_file00 test_file01 test_file02
    TEXT
    with_work_dir do
      r, w = IO.pipe
      create_test_files(3)
      screen = Screen.new(EntryList.new)
      w.puts screen.out
      w.close
      assert_equal expected, r.gets.to_s
    end
  end

  # ファイルの数が多い場合、画面に表示できる最大幅でファイルを並べて縦列が計算される
  def test_out_with_many_entries
    file_num = 13

    with_work_dir do
      create_test_files(file_num)
      r, w = IO.pipe
      screen = Screen.new(EntryList.new)
      w.puts screen.out
      w.close

      expected = <<~TEXT
        test_file00 test_file03 test_file06 test_file09 test_file12
        test_file01 test_file04 test_file07 test_file10
        test_file02 test_file05 test_file08 test_file11
      TEXT
      assert_equal expected, r.gets('')
    end
  end

  # ディレクトリ内にentryがなにも無い場合は何も表示しない
  def test_with_empty
    with_work_dir do
      r, w = IO.pipe
      screen = Screen.new(EntryList.new)
      w.puts screen.out
      w.close
      assert_nil r.gets('')
    end
  end

  # 複数のディレクトリが指定された場合、ディレクトリを先頭ラベルに内容を表示する
  def test_multiple_directory
    with_work_dir do
      system 'mkdir test_dir1; touch test_dir1/test_file1 test_dir1/test_file2'
      system 'mkdir test_dir2; touch test_dir2/test_file3 test_dir2/test_file4'


    end
  end
end
