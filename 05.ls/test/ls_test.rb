#!/usr/bin/env ruby

# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/ls'
require_relative './test_tools'
require 'io/console/size'
require 'pathname'

class LsSimpleTest < Minitest::Test
  def setup
    @test_tools = TestTools.new
    # テストのために十分なコンソールの幅がなかった場合はエラーとする
    raise "テストに必要なコンソールの表示幅がありません。#{22 * 3}以上の幅を確保してください" if IO.console_size[1] < 66

    @test_ls = Ls.new
    @test_ls.entries = ["#{@test_tools.test_dir}/"]
  end

  def test_vacant_dir
    assert_equal '', @test_tools.capture_stdout(@test_ls)
  end

  def test_one_file_with_ascii_name
    @test_tools.create_tmp_files(1)
    assert_equal "test_file1\n", @test_tools.capture_stdout(@test_ls)
  end

  def test_one_file_with_japanese_name
    @test_tools.create_tmp_files(1, is_ja: true)
    assert_equal "日本語のファイル1\n", @test_tools.capture_stdout(@test_ls)
  end

  def test_absolute_filepath
    @test_tools.create_tmp_files(1)
    file_path = File.absolute_path(("#{@test_tools.test_dir}/test_file1"))
    @test_ls.entries = [file_path]
    assert_equal "#{file_path}\n", @test_tools.capture_stdout(@test_ls)
  end

  def test_relative_filepath
    @test_tools.create_tmp_files(1)
    file_path = Pathname.new("#{@test_tools.test_dir}/test_file1")
    relative_file_path = file_path.relative_path_from(Dir.pwd).to_s
    @test_ls.entries = [relative_file_path]
    assert_equal "#{relative_file_path}\n", @test_tools.capture_stdout(@test_ls)
  end

  def test_one_dir_with_ascii_name
    @test_tools.create_tmp_dirs(1)
    assert_equal "test_dir1\n", @test_tools.capture_stdout(@test_ls)
  end

  def test_one_dir_with_japanese_name
    @test_tools.create_tmp_dirs(1, is_ja: true)
    assert_equal "日本語のディレクトリ1\n", @test_tools.capture_stdout(@test_ls)
  end

  def teardown
    @test_tools.cleanup
  end
end

class LsMultipleEntriesTest < Minitest::Test
  def setup
    @test_tools = TestTools.new
    # テストのために十分なコンソールの幅がなかった場合はエラーとする
    raise "テストに必要なコンソールの表示幅がありません。#{22 * 3}以上の幅を確保してください" if IO.console_size[1] < 66

    @test_ls = Ls.new
    @test_ls.entries = ["#{@test_tools.test_dir}/"]
  end

  def test_many_files_with_same_format
    expected1 = <<~TEXT
      test_file1 test_file4 test_file7
      test_file2 test_file5
      test_file3 test_file6
    TEXT
    @test_tools.create_tmp_files(7)
    assert_equal expected1, @test_tools.capture_stdout(@test_ls)
  end

  def test_many_files_with_same_format_part2
    expected2 = <<~TEXT
      test_file1 test_file3 test_file4
      test_file2
    TEXT
    @test_tools.create_tmp_files(4)
    assert_equal expected2, @test_tools.capture_stdout(@test_ls)
  end

  def test_many_japanese_files_with_same_format
    expected = <<~TEXT
      日本語のファイル1 日本語のファイル4 日本語のファイル7
      日本語のファイル2 日本語のファイル5
      日本語のファイル3 日本語のファイル6
    TEXT
    @test_tools.create_tmp_files(7, is_ja: true)
    assert_equal expected, @test_tools.capture_stdout(@test_ls)
  end

  def test_many_files_mixed_format
    # test_file1 = 9スペース分 日本語のファイル1 = 17スペース分
    expected = <<~TEXT
      test_file1        test_file4        日本語のファイル3
      test_file2        日本語のファイル1
      test_file3        日本語のファイル2
    TEXT
    @test_tools.create_tmp_files(4)
    @test_tools.create_tmp_files(3, is_ja: true)
    assert_equal expected, @test_tools.capture_stdout(@test_ls)
  end

  def test_many_entries_mixed_format
    # test_file1 = 10スペース分
    # 日本語のファイル1 = 17スペース分
    # test_dir = 8スペース分
    # 日本語のディレクトリ1 = 21スペース分
    expected = <<~TEXT
      test_dir1             test_file2            日本語のファイル1
      test_dir2             日本語のディレクトリ1 日本語のファイル2
      test_file1            日本語のディレクトリ2
    TEXT

    @test_tools.create_tmp_files(2)
    @test_tools.create_tmp_files(2, is_ja: true)
    @test_tools.create_tmp_dirs(2)
    @test_tools.create_tmp_dirs(2, is_ja: true)
    assert_equal expected, @test_tools.capture_stdout(@test_ls)
  end

  def test_many_entries_mixed_format_include_hidden_entries
    # test_file1 = 10スペース分
    # 日本語のファイル1 = 17スペース分
    # test_dir = 8スペース分
    # 日本語のディレクトリ1 = 21スペース分
    expected = <<~TEXT
      test_dir1             test_file2            日本語のファイル1
      test_dir2             日本語のディレクトリ1 日本語のファイル2
      test_file1            日本語のディレクトリ2
    TEXT

    @test_tools.create_tmp_files(2)
    @test_tools.create_tmp_files(2, is_ja: true)
    @test_tools.create_tmp_dirs(2)
    @test_tools.create_tmp_dirs(2, is_ja: true)

    @test_tools.create_tmp_files(2, is_hidden: true)
    @test_tools.create_tmp_dirs(3, is_hidden: true)
    @test_tools.create_tmp_files(2, is_hidden: true, is_ja: true)
    @test_tools.create_tmp_dirs(3, is_hidden: true, is_ja: true)

    assert_equal expected, @test_tools.capture_stdout(@test_ls)
  end

  def test_many_entries_include_long_filename
    # ディレクトリ内に長いファイル名が混じると出力を強制的に1行にする
    @test_tools.create_tmp_files(2)
    long_filename = 'longlonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglongname'
    expected = <<~TEXT
      #{long_filename}
      test_file1
      test_file2
    TEXT
    system("touch #{@test_tools.test_dir}/#{long_filename}")
    assert_equal expected, @test_tools.capture_stdout(@test_ls)
  end

  def teardown
    @test_tools.cleanup
  end
end

class LsManyEntriesWithReverseOptionTest < Minitest::Test
  def setup
    @test_tools = TestTools.new
    # テストのために十分なコンソールの幅がなかった場合はエラーとする
    raise "テストに必要なコンソールの表示幅がありません。#{22 * 3}以上の幅を確保してください" if IO.console_size[1] < 66

    @test_ls = Ls.new(['SORT_REVERSE'])
    @test_ls.entries = ["#{@test_tools.test_dir}/"]
  end

  def test_many_files_mixed_format
    # test_file1 = 9スペース分 日本語のファイル1 = 17スペース分
    expected = <<~TEXT
      日本語のファイル3 test_file4        test_file1
      日本語のファイル2 test_file3
      日本語のファイル1 test_file2
    TEXT
    @test_tools.create_tmp_files(4)
    @test_tools.create_tmp_files(3, is_ja: true)
    assert_equal expected, @test_tools.capture_stdout(@test_ls)
  end

  def test_many_entries_mixed_format_include_hidden_entries
    # test_file1 = 10スペース分
    # 日本語のファイル1 = 17スペース分
    # test_dir = 8スペース分
    # 日本語のディレクトリ1 = 21スペース分
    expected = <<~TEXT
      日本語のファイル2     日本語のディレクトリ1 test_dir2
      日本語のファイル1     test_file2            test_dir1
      日本語のディレクトリ2 test_file1
    TEXT

    @test_tools.create_tmp_files(2)
    @test_tools.create_tmp_files(2, is_ja: true)
    @test_tools.create_tmp_dirs(2)
    @test_tools.create_tmp_dirs(2, is_ja: true)

    @test_tools.create_tmp_files(2, is_hidden: true)
    @test_tools.create_tmp_dirs(3, is_hidden: true)
    @test_tools.create_tmp_files(2, is_hidden: true, is_ja: true)
    @test_tools.create_tmp_dirs(3, is_hidden: true, is_ja: true)

    assert_equal expected, @test_tools.capture_stdout(@test_ls)
  end

  def teardown
    @test_tools.cleanup
  end
end

class LsManyArgTest < Minitest::Test
  def setup
    @test_tools = TestTools.new
    # テストのために十分なコンソールの幅がなかった場合はエラーとする
    raise "テストに必要なコンソールの表示幅がありません。#{22 * 3}以上の幅を確保してください" if IO.console_size[1] < 66

    @test_ls = Ls.new
    @test_ls.entries = ["#{@test_tools.test_dir}/"]
  end

  def test_many_file_args
    expected = <<~TEXT
      #{@test_tools.test_dir}/test_file1
      #{@test_tools.test_dir}/test_file2
    TEXT
    @test_tools.create_tmp_files(2)
    @test_ls.entries = [
      "#{@test_tools.test_dir}/test_file1",
      "#{@test_tools.test_dir}/test_file2"
    ]
    assert_equal expected, @test_tools.capture_stdout(@test_ls)
  end

  def test_many_vacant_dir_args
    expected = <<~TEXT
      #{@test_tools.test_dir}/test_dir1/:

      #{@test_tools.test_dir}/test_dir2/:
    TEXT
    @test_tools.create_tmp_dirs(2)
    @test_ls.entries = [
      "#{@test_tools.test_dir}/test_dir1/",
      "#{@test_tools.test_dir}/test_dir2/"
    ]
    assert_equal expected, @test_tools.capture_stdout(@test_ls)
  end

  def test_many_dir_args
    expected = <<~TEXT
      #{@test_tools.test_dir}/test_dir1/:
      test_file1 test_file4 test_file7
      test_file2 test_file5
      test_file3 test_file6

      #{@test_tools.test_dir}/test_dir2/:
      test_dir1  test_file2 test_file3
      test_file1

      #{@test_tools.test_dir}/test_dir3/:
      test_file1
    TEXT
    @test_tools.create_tmp_dirs(3)
    @test_tools.create_tmp_files(7, sub_dir: 'test_dir1')
    @test_tools.create_tmp_files(3, sub_dir: 'test_dir2')
    @test_tools.create_tmp_dirs(1, sub_dir: 'test_dir2')
    @test_tools.create_tmp_files(1, sub_dir: 'test_dir3')

    @test_ls.entries = [
      "#{@test_tools.test_dir}/test_dir1/",
      "#{@test_tools.test_dir}/test_dir2/",
      "#{@test_tools.test_dir}/test_dir3/"
    ]
    assert_equal expected, @test_tools.capture_stdout(@test_ls)
  end

  def test_mixed_args
    expected1 = <<~TEXT
      #{@test_tools.test_dir}/test_file1
      #{@test_tools.test_dir}/test_file2
      #{@test_tools.test_dir}/test_file3

      #{@test_tools.test_dir}/test_dir1/:
      test_file1 test_file4 test_file7
      test_file2 test_file5
      test_file3 test_file6

      #{@test_tools.test_dir}/test_dir2/:
      test_file1 test_file3 test_file4
      test_file2
    TEXT
    @test_tools.create_tmp_dirs(2)
    @test_tools.create_tmp_files(3)
    @test_tools.create_tmp_files(7, sub_dir: 'test_dir1')
    @test_tools.create_tmp_files(4, sub_dir: 'test_dir2')
    @test_ls.entries = [
      "#{@test_tools.test_dir}/test_file1",
      "#{@test_tools.test_dir}/test_file2",
      "#{@test_tools.test_dir}/test_file3",
      "#{@test_tools.test_dir}/test_dir1/",
      "#{@test_tools.test_dir}/test_dir2/"
    ]
    assert_equal expected1, @test_tools.capture_stdout(@test_ls)
  end

  def teardown
    @test_tools.cleanup
  end
end

class LsManyArgWithReverseTest < Minitest::Test
  def setup
    @test_tools = TestTools.new
    # テストのために十分なコンソールの幅がなかった場合はエラーとする
    raise "テストに必要なコンソールの表示幅がありません。#{22 * 3}以上の幅を確保してください" if IO.console_size[1] < 66

    @test_ls = Ls.new(['SORT_REVERSE'])
    @test_ls.entries = ["#{@test_tools.test_dir}/"]
  end

  def test_many_file_args
    expected = <<~TEXT
      #{@test_tools.test_dir}/test_file2
      #{@test_tools.test_dir}/test_file1
    TEXT
    @test_tools.create_tmp_files(2)
    @test_ls.entries = [
      "#{@test_tools.test_dir}/test_file2",
      "#{@test_tools.test_dir}/test_file1"
    ]
    assert_equal expected, @test_tools.capture_stdout(@test_ls)
  end

  def test_many_dir_args
    expected = <<~TEXT
      #{@test_tools.test_dir}/test_dir3/:
      test_file1

      #{@test_tools.test_dir}/test_dir2/:
      test_file3 test_file1 test_dir1
      test_file2

      #{@test_tools.test_dir}/test_dir1/:
      test_file7 test_file4 test_file1
      test_file6 test_file3
      test_file5 test_file2
    TEXT
    @test_tools.create_tmp_dirs(3)
    @test_tools.create_tmp_files(7, sub_dir: 'test_dir1')
    @test_tools.create_tmp_files(3, sub_dir: 'test_dir2')
    @test_tools.create_tmp_dirs(1, sub_dir: 'test_dir2')
    @test_tools.create_tmp_files(1, sub_dir: 'test_dir3')

    @test_ls.entries = [
      "#{@test_tools.test_dir}/test_dir1/",
      "#{@test_tools.test_dir}/test_dir2/",
      "#{@test_tools.test_dir}/test_dir3/"
    ]
    assert_equal expected, @test_tools.capture_stdout(@test_ls)
  end

  def teardown
    @test_tools.cleanup
  end
end

class LsHiddenEntryTest < Minitest::Test
  def setup
    @test_tools = TestTools.new
    # テストのために十分なコンソールの幅がなかった場合はエラーとする
    raise "テストに必要なコンソールの表示幅がありません。#{22 * 3}以上の幅を確保してください" if IO.console_size[1] < 66

    @test_ls = Ls.new(['SHOW_DOTMATCH'])
    @test_ls.entries = ["#{@test_tools.test_dir}/"]
  end

  def test_one_hiddenfile_with_ascii_name
    @test_tools.create_tmp_files(1, is_hidden: true)
    assert_equal ".           .test_file1\n", @test_tools.capture_stdout(@test_ls)
  end

  def test_one_hiddenfile_with_japanese_name
    @test_tools.create_tmp_files(1, is_ja: true, is_hidden: true)
    assert_equal ".                  .日本語のファイル1\n", @test_tools.capture_stdout(@test_ls)
  end

  def test_one_hiddendir_with_ascii_name
    @test_tools.create_tmp_dirs(1, is_hidden: true)
    assert_equal ".          .test_dir1\n", @test_tools.capture_stdout(@test_ls)
  end

  def test_one_hiddendir_with_japanese_name
    @test_tools.create_tmp_dirs(1, is_ja: true, is_hidden: true)
    assert_equal ".                      .日本語のディレクトリ1\n", @test_tools.capture_stdout(@test_ls)
  end

  def test_absolute_hiddenfile_path
    @test_tools.create_tmp_files(1, is_hidden: true)
    file_path = File.absolute_path(("#{@test_tools.test_dir}/.test_file1"))
    @test_ls.entries = [file_path]
    assert_equal "#{file_path}\n", @test_tools.capture_stdout(@test_ls)
  end

  def test_relative_hiddenfile_path
    @test_tools.create_tmp_files(1, is_hidden: true)
    file_path = Pathname.new("#{@test_tools.test_dir}/.test_file1")
    relative_file_path = file_path.relative_path_from(Dir.pwd).to_s
    @test_ls.entries = [relative_file_path]
    assert_equal "#{relative_file_path}\n", @test_tools.capture_stdout(@test_ls)
  end

  def teardown
    @test_tools.cleanup
  end
end

class LsNoOptionHiddenEntryTest < Minitest::Test
  def setup
    @test_tools = TestTools.new
    # テストのために十分なコンソールの幅がなかった場合はエラーとする
    raise "テストに必要なコンソールの表示幅がありません。#{22 * 3}以上の幅を確保してください" if IO.console_size[1] < 66

    @test_ls = Ls.new
    @test_ls.entries = ["#{@test_tools.test_dir}/"]
  end

  def test_one_hiddenfile_with_ascii_name
    @test_tools.create_tmp_files(1, is_hidden: true)
    assert_equal '', @test_tools.capture_stdout(@test_ls)
  end

  def test_one_hiddenfile_with_japanese_name
    @test_tools.create_tmp_files(1, is_ja: true, is_hidden: true)
    assert_equal '', @test_tools.capture_stdout(@test_ls)
  end

  def test_one_hiddendir_with_ascii_name
    @test_tools.create_tmp_dirs(1, is_hidden: true)
    assert_equal '', @test_tools.capture_stdout(@test_ls)
  end

  def test_one_hiddendir_with_japanese_name
    @test_tools.create_tmp_dirs(1, is_ja: true, is_hidden: true)
    assert_equal '', @test_tools.capture_stdout(@test_ls)
  end

  # lsはオプションがなくても隠しファイルを指定した場合は結果に出力する
  def test_absolute_hiddenfile_path
    @test_tools.create_tmp_files(1, is_hidden: true)
    file_path = File.absolute_path(("#{@test_tools.test_dir}/.test_file1"))
    @test_ls.entries = [file_path]
    assert_equal "#{file_path}\n", @test_tools.capture_stdout(@test_ls)
  end

  # lsはオプションがなくても隠しファイルを指定した場合は結果に出力する
  def test_relative_hiddenfile_path
    @test_tools.create_tmp_files(1, is_hidden: true)
    file_path = Pathname.new("#{@test_tools.test_dir}/.test_file1")
    relative_file_path = file_path.relative_path_from(Dir.pwd).to_s
    @test_ls.entries = [relative_file_path]
    assert_equal "#{relative_file_path}\n", @test_tools.capture_stdout(@test_ls)
  end

  def teardown
    @test_tools.cleanup
  end
end

class LsManyArgIncludeHiddenTest < Minitest::Test
  def setup
    @test_tools = TestTools.new
    # テストのために十分なコンソールの幅がなかった場合はエラーとする
    raise "テストに必要なコンソールの表示幅がありません。#{22 * 3}以上の幅を確保してください" if IO.console_size[1] < 66

    @test_ls = Ls.new(['SHOW_DOTMATCH'])
    @test_ls.entries = ["#{@test_tools.test_dir}/"]
  end

  def test_many_file_args
    expected = <<~TEXT
      #{@test_tools.test_dir}/.test_file1
      #{@test_tools.test_dir}/test_file1
    TEXT
    @test_tools.create_tmp_files(1)
    @test_tools.create_tmp_files(1, is_hidden: true)
    @test_ls.entries = [
      "#{@test_tools.test_dir}/.test_file1",
      "#{@test_tools.test_dir}/test_file1"
    ]
    assert_equal expected, @test_tools.capture_stdout(@test_ls)
  end

  def test_many_vacant_dir_args
    expected = <<~TEXT
      #{@test_tools.test_dir}/.test_dir1/:
      .

      #{@test_tools.test_dir}/test_dir1/:
      .
    TEXT
    @test_tools.create_tmp_dirs(1)
    @test_tools.create_tmp_dirs(1, is_hidden: true)
    @test_ls.entries = [
      "#{@test_tools.test_dir}/.test_dir1/",
      "#{@test_tools.test_dir}/test_dir1/"
    ]
    assert_equal expected, @test_tools.capture_stdout(@test_ls)
  end

  def test_many_dir_args
    expected = <<~TEXT
      #{@test_tools.test_dir}/.test_dir1/:
      .          test_file1 test_file3
      test_dir1  test_file2

      #{@test_tools.test_dir}/test_dir1/:
      .          test_file2 test_file5
      test_dir1  test_file3
      test_file1 test_file4
    TEXT
    @test_tools.create_tmp_dirs(1)
    @test_tools.create_tmp_dirs(1, is_hidden: true)

    @test_tools.create_tmp_files(3, sub_dir: '.test_dir1')
    @test_tools.create_tmp_dirs(1, sub_dir: '.test_dir1')
    @test_tools.create_tmp_files(5, sub_dir: 'test_dir1')
    @test_tools.create_tmp_dirs(1, sub_dir: 'test_dir1')

    @test_ls.entries = [
      "#{@test_tools.test_dir}/.test_dir1/",
      "#{@test_tools.test_dir}/test_dir1/"
    ]
    assert_equal expected, @test_tools.capture_stdout(@test_ls)
  end

  def test_mixed_args
    expected1 = <<~TEXT
      #{@test_tools.test_dir}/.test_file1
      #{@test_tools.test_dir}/.test_file2
      #{@test_tools.test_dir}/test_file1

      #{@test_tools.test_dir}/.test_dir1/:
      .           .test_file3 test_file3
      .test_file1 test_file1  test_file4
      .test_file2 test_file2
    TEXT
    @test_tools.create_tmp_files(2, is_hidden: true)
    @test_tools.create_tmp_files(1)

    @test_tools.create_tmp_dirs(1, is_hidden: true)
    @test_tools.create_tmp_files(4, sub_dir: '.test_dir1')
    @test_tools.create_tmp_files(3, is_hidden: true, sub_dir: '.test_dir1')
    @test_ls.entries = [
      "#{@test_tools.test_dir}/.test_file1",
      "#{@test_tools.test_dir}/.test_file2",
      "#{@test_tools.test_dir}/test_file1",
      "#{@test_tools.test_dir}/.test_dir1/"
    ]
    assert_equal expected1, @test_tools.capture_stdout(@test_ls)
  end

  def teardown
    @test_tools.cleanup
  end
end

class LsManyArgIncludeHiddenWithReverseTest < Minitest::Test
  def setup
    @test_tools = TestTools.new
    # テストのために十分なコンソールの幅がなかった場合はエラーとする
    raise "テストに必要なコンソールの表示幅がありません。#{22 * 3}以上の幅を確保してください" if IO.console_size[1] < 66

    @test_ls = Ls.new(%w[SHOW_DOTMATCH SORT_REVERSE])
    @test_ls.entries = [@test_tools.test_dir]
  end

  def test_many_file_args
    expected = <<~TEXT
      #{@test_tools.test_dir}/test_file1
      #{@test_tools.test_dir}/.test_file1
    TEXT
    @test_tools.create_tmp_files(1)
    @test_tools.create_tmp_files(1, is_hidden: true)
    @test_ls.entries = [
      "#{@test_tools.test_dir}/.test_file1",
      "#{@test_tools.test_dir}/test_file1"
    ]
    assert_equal expected, @test_tools.capture_stdout(@test_ls)
  end

  def test_mixed_args
    expected1 = <<~TEXT
      #{@test_tools.test_dir}/test_file1
      #{@test_tools.test_dir}/.test_file2
      #{@test_tools.test_dir}/.test_file1

      #{@test_tools.test_dir}/.test_dir1/:
      test_file4  test_file1  .test_file1
      test_file3  .test_file3 .
      test_file2  .test_file2
    TEXT
    @test_tools.create_tmp_files(2, is_hidden: true)
    @test_tools.create_tmp_files(1)

    @test_tools.create_tmp_dirs(1, is_hidden: true)
    @test_tools.create_tmp_files(4, sub_dir: '.test_dir1')
    @test_tools.create_tmp_files(3, is_hidden: true, sub_dir: '.test_dir1')
    @test_ls.entries = [
      "#{@test_tools.test_dir}/.test_file1",
      "#{@test_tools.test_dir}/.test_file2",
      "#{@test_tools.test_dir}/test_file1",
      "#{@test_tools.test_dir}/.test_dir1/"
    ]
    assert_equal expected1, @test_tools.capture_stdout(@test_ls)
  end

  def teardown
    @test_tools.cleanup
  end
end
