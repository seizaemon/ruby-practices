# frozen_string_literal: true

require 'minitest/autorun'
require 'io/console/size'
require 'time'
require_relative '../lib/screen'
require_relative '../lib/ls_file_stat'
require_relative './work_dir'

# テスト用のファイル名は11文字固定
FILENAME_CHAR_COUNT = 11
# テスト用のコンソールは固定
TEST_CONSOLE_WIDTH = 80

class ScreenTest < Minitest::Test
  include WorkDir

  def setup
    # _, @console_width = IO.console_size
    @console_width = TEST_CONSOLE_WIDTH
  end

  def create_test_files(max_file_num)
    (0..max_file_num - 1).map do |n|
      suffix = format('%02d', n)
      File.open("test_file#{suffix}", 'w', 0o755) {}
      "test_file#{suffix}"
    end
  end

  # ファイルが少ない場合ファイル一覧は横にならべられる
  def test_out_with_few_files
    expected = <<~TEXT
      test_file00 test_file01 test_file02
    TEXT
    with_work_dir do
      r, w = IO.pipe
      stats = LsFileStat.bulk_create create_test_files(3)
      screen = Screen.new stats
      w.puts screen.out
      w.close

      assert_equal expected, r.gets('')
    end
  end

  # ファイルの数が多い場合、画面に表示できる最大幅でファイルを並べて縦列が計算される
  def test_out_with_many_files
    file_num = 13

    with_work_dir do
      r, w = IO.pipe
      stats = LsFileStat.bulk_create create_test_files(file_num)
      screen = Screen.new stats
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

  # ディレクトリ内にfileがなにも無い場合は何も表示しない
  def test_with_empty_dir
    with_work_dir do
      r, w = IO.pipe
      stats = LsFileStat.bulk_create []
      screen = Screen.new stats
      w.puts screen.out
      w.close
      assert_nil r.gets('')
    end
  end
end

class ScreenInDetailTest < Minitest::Test
  include WorkDir
  def setup
    @console_width = TEST_CONSOLE_WIDTH
    @user_name = Etc.getpwuid(Process::UID.rid).name
    @group_name = Etc.getgrgid(Process::GID.rid).name
  end

  # out_in_deatailはファイルの詳細情報を一列で表示する
  def test_detail_output
    with_work_dir do
      date_str = Time.now.strftime('%-m %-d %H:%M')

      # rubocop:disable Layout/TrailingWhitespace
      expected = <<~TEXT
        -rwxr-xr--  1 #{@user_name}  #{@group_name}  100  #{date_str} test_file1     
        -r---w---x  1 #{@user_name}  #{@group_name}    0  #{date_str} test_file2     
        -rwxrwxrwx  1 #{@user_name}  #{@group_name}    0  #{date_str} test_long_file1
      TEXT
      # rubocop:enable Layout/TrailingWhitespace

      system 'touch test_file1 ; chmod 754 test_file1; dd if=/dev/zero of=test_file1 bs=100 count=1'
      system 'touch test_file2 ; chmod 421 test_file2'
      system 'touch test_long_file1 ; chmod 777 test_long_file1'
      stats = LsFileStat.bulk_create %w[test_file2 test_file1 test_long_file1]
      screen = Screen.new(stats)
      r, w = IO.pipe
      w.puts screen.out_in_detail
      w.close
      assert_equal expected, r.gets('')
    end
  end
end
