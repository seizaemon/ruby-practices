# frozen_string_literal: true

require 'minitest/autorun'
require 'time'
require_relative '../lib/screen'
require_relative '../lib/ls_file_stat'
require_relative './work_dir'

class ScreenTest < Minitest::Test
  include WorkDir

  def create_test_files
    system 'touch test_file00 ; touch test_file01 ; touch test_long_file1'
    %w[test_file00 test_file01 test_long_file1]
  end

  # headerオプションなしの場合ディレクトリ表示の場合でもディレクトリ名は表示されない
  def test_show_without_header_option
    expected = <<~TEXT
      test_file00     test_file01     test_long_file1
    TEXT

    with_work_dir do
      stats = create_test_files.map do |file|
        LsFileStat.new(file)
      end
      src_data = { '' => [], 'test_dir' => stats }
      screen = Screen.new(src_data)

      assert_output(expected) { screen.show }
    end
  end

  # headerオプションをつけるとディレクトリ内の結果表示でディレクトリ名が表示される
  def test_show_with_header_option
    expected = <<~TEXT
      test_dir:
      test_file00     test_file01     test_long_file1
    TEXT

    with_work_dir do
      system 'mkdir test_dir'

      stats = create_test_files.map do |file|
        LsFileStat.new(file)
      end
      src_data = { '' => [], 'test_dir' => stats }
      screen = Screen.new(src_data, { header: true })

      assert_output(expected) { screen.show }
    end
  end

  # 通常ファイルとディレクトリ名は通常辞書順で並ぶ
  def test_show_with_few_files
    expected = <<~TEXT
      test_file00     test_file01     test_long_file1

      test_dir1:
      test_file00     test_file01     test_long_file1

      test_dir2:
      test_file00     test_file01     test_long_file1
    TEXT
    with_work_dir do
      stats = create_test_files.map do |file|
        LsFileStat.new(file)
      end
      src_data = { '' => stats, 'test_dir1' => stats, 'test_dir2' => stats }
      screen = Screen.new(src_data, { header: true })

      assert_output(expected) { screen.show }
    end
  end

  # ディレクトリ内にfileがなにも無い場合は何も表示しない
  def test_show_with_empty_dir
    with_work_dir do
      src_data = { '' => [] }
      screen = Screen.new(src_data)

      assert_output("\n") { screen.show }
    end
  end

  # ファイル名の長さが異なり複数行表示される場合
end

class ScreenInDetailTest < Minitest::Test
  include WorkDir
  def setup
    @user_name = Etc.getpwuid(Process::UID.rid).name
    @group_name = Etc.getgrgid(Process::GID.rid).name
  end

  def create_test_files_in_long_option_cases(base_dir = '.')
    Dir.chdir(base_dir) do
      system 'touch test_file1 ; chmod 754 test_file1; dd if=/dev/zero of=test_file1 bs=100 count=1'
      system 'touch test_file2 ; chmod 421 test_file2; chgrp everyone test_file2'
      system 'touch test_long_file1 ; chmod 777 test_long_file1'
    end
    %w[test_file1 test_file2 test_long_file1]
  end

  # long_formatオプションはファイルの詳細情報を一列で表示する
  def test_show_with_long_format_option
    date_str = Time.now.strftime('%_m %_d %H:%M')
    expected = <<~TEXT
      -rwxr-xr--  1 #{@user_name}  staff     100 #{date_str} test_file1
      -r---w---x  1 #{@user_name}  everyone    0 #{date_str} test_file2
      -rwxrwxrwx  1 #{@user_name}  staff       0 #{date_str} test_long_file1
    TEXT

    with_work_dir do
      stats = create_test_files_in_long_option_cases.map do |file|
        LsFileStat.new(file)
      end

      src_data = { '' => stats }
      screen = Screen.new(src_data, { long_format: true })

      assert_output(expected) { screen.show }
    end
  end

  # headerオプション
end
