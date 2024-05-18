# frozen_string_literal: true

require 'minitest/autorun'
require 'time'
require 'pathname'
require_relative '../lib/screen'
require_relative '../lib/ls_file_stat'
require_relative './work_dir'

class ScreenTest < Minitest::Test
  include WorkDir

  def create_test_files(dir_path = '.')
    system "mkdir #{dir_path}" if dir_path != '.'
    file_paths = %w[test_file00 test_file01 test_long_file1]

    file_paths.map do |file_path|
      Dir.chdir(dir_path) { system "touch #{file_path}" }
      Pathname.new(dir_path).join(file_path).to_s
    end
  end

  # headerオプションなしの場合ディレクトリ表示の場合でもディレクトリ名は表示されない
  def test_show
    expected = <<~TEXT
      test_file00     test_file01     test_long_file1
    TEXT

    with_work_dir do
      stats = create_test_files('test_dir').map do |file|
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
      stats = create_test_files('test_dir').map do |file|
        LsFileStat.new(file)
      end
      src_data = { '' => [], 'test_dir' => stats }
      screen = Screen.new(src_data, { header: true })

      assert_output(expected) { screen.show }
    end
  end

  # 通常ファイルとディレクトリ名は通常辞書順で並ぶ
  def test_show_with_files_and_dirs
    expected = <<~TEXT
      test_file00     test_file01     test_long_file1

      test_dir1:
      test_file00     test_file01     test_long_file1

      test_dir2:
      test_file00     test_file01     test_long_file1
    TEXT
    with_work_dir do
      src_data = {}
      src_data[''] = create_test_files.map { |file_path| LsFileStat.new(file_path) }
      %w[test_dir1 test_dir2].each do |dir_path|
        src_data[dir_path] =
          create_test_files(dir_path).map do |file_path|
            LsFileStat.new(file_path)
          end
      end
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
end

class ScreenInDetailTest < Minitest::Test
  include WorkDir
  def setup
    @user_name = Etc.getpwuid(Process::UID.rid).name
  end

  def create_test_files_in_long_option_cases(base_dir = '.')
    Dir.chdir(base_dir) do
      system 'touch test_file1 ; chmod 754 test_file1; dd if=/dev/zero of=test_file1 bs=100 count=1'
      system 'touch test_file2 ; chmod 421 test_file2; chgrp everyone test_file2'
      system 'touch test_long_file1 ; chmod 777 test_long_file1'
    end
    %w[test_file1 test_file2 test_long_file1].map do |file_path|
      Pathname.new(base_dir).join(file_path).to_s
    end
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

  # long_formatオプションをつけディレクトリ内容を表示するとtotalを表示する
  def test_show_directory_with_long_format
    date_str = Time.now.strftime('%_m %_d %H:%M')
    expected = <<~TEXT
      test_dir:
      total 8
      -rwxr-xr--  1 #{@user_name}  staff     100 #{date_str} test_file1
      -r---w---x  1 #{@user_name}  everyone    0 #{date_str} test_file2
      -rwxrwxrwx  1 #{@user_name}  staff       0 #{date_str} test_long_file1
    TEXT

    with_work_dir do
      system 'mkdir test_dir'
      stats = create_test_files_in_long_option_cases('test_dir').map do |file|
        LsFileStat.new(file)
      end

      src_data = { '' => [], 'test_dir' => stats }
      screen = Screen.new(src_data, { long_format: true, header: true })

      assert_output(expected) { screen.show }
    end
  end
end
