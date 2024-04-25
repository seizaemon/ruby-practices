# frozen_string_literal: true

require 'minitest/autorun'
require 'tempfile'
require_relative '../test/work_dir'

class LsTest < Minitest::Test
  include WorkDir

  def ready_test_env(&block)
    with_work_dir do
      system 'touch test_file1 test_file2 .test_hidden'
      system 'mkdir test_dir; touch test_dir/test_file3 test_dir/test_file4'
      block.call
    end
  end

  # 引数なしの場合はカレントディレクトリの内容を調べる
  def test_ls_normal
    ready_test_env do
      r, w = IO.pipe
      system "ruby #{__dir__}/../ls.rb", out: w
      w.close

      expected = <<~TEXT
        test_dir   test_file1 test_file2
      TEXT
      assert_equal expected, r.gets('')
    end
  end

  # ディレクトリ指定
  def test_ls_with_dir_argument
    ready_test_env do
      r, w = IO.pipe
      system "ruby #{__dir__}/../ls.rb test_dir", out: w
      w.close

      expected = <<~TEXT
        test_file3 test_file4
      TEXT
      assert_equal expected, r.gets('')
    end
  end

  # 複数の引数を指定した場合は通常ファイルを優先して出力する
  def test_ls_with_file_and_directory
    ready_test_env do
      r, w = IO.pipe
      system "ruby #{__dir__}/../ls.rb test_dir test_file1", out: w
      w.close

      expected = <<~TEXT
        test_file1

        test_dir:
        test_file3 test_file4
      TEXT
      assert_equal expected, r.gets(nil)
    end
  end

  # 絶対パスを指定した場合はその内容を表示する
  def test_ls_with_absolute_path
    Tempfile.open('test_file', '/tmp') do |f|
      r, w = IO.pipe
      system "ruby #{__dir__}/../ls.rb #{f.path}", out: w
      w.close

      expected = <<~TEXT
        #{f.path}
      TEXT
      assert_equal expected, r.gets(nil)
    end
  end
end
