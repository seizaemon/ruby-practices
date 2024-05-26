# frozen_string_literal: true

require 'minitest/autorun'
require 'tempfile'
require_relative '../test/work_dir'

class LsArgvTest < Minitest::Test
  include WorkDir

  def create_test_files(&block)
    with_work_dir do
      system 'touch test_file1 test_file2 .test_hidden'
      system 'mkdir test_dir; touch test_dir/test_file3 test_dir/test_file4 test_dir/.test_hidden'
      block.call
    end
  end

  # 引数なしの場合はカレントディレクトリの内容を調べる
  def test_argv_with_nothing
    create_test_files do
      r, w = IO.pipe
      system "ruby #{__dir__}/../ls.rb", out: w
      w.close

      expected = <<~TEXT
        test_dir   test_file1 test_file2
      TEXT
      assert_equal expected, r.gets(nil)
    end
  end

  # ディレクトリ指定
  def test_argv_with_directory
    create_test_files do
      r, w = IO.pipe
      system "ruby #{__dir__}/../ls.rb test_dir", out: w
      w.close

      expected = <<~TEXT
        test_file3 test_file4
      TEXT
      assert_equal expected, r.gets(nil)
    end
  end

  # 複数の引数を指定した場合は通常ファイルを優先して出力する
  def test_argv_with_file_and_directory
    create_test_files do
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
  def test_argv_with_absolute_path
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

class LsOptionTest < Minitest::Test
  include WorkDir
  def setup
    @user_name = Etc.getpwuid(Process::UID.rid).name
  end

  def create_test_files(&block)
    with_work_dir do
      system 'touch test_file1 test_file2 .test_hidden'
      system 'mkdir test_dir; touch test_dir/test_file3 test_dir/test_file4 test_dir/.test_hidden'
      system 'mkdir test_dir2; touch test_dir2/test_file5 test_dir2/test_file6 test_dir2/.test_hidden2'
      system 'dd if=/dev/zero of=test_file1 bs=100 count=1'
      system 'dd if=/dev/zero of=test_dir/test_file3 bs=100 count=1'
      system 'dd if=/dev/zero of=test_dir2/test_file6 bs=100 count=1'
      system 'chgrp everyone test_file2 test_dir/test_file3 test_dir2/test_file6'
      block.call
    end
  end

  # lオプションを付けた場合は詳細表示になる
  def test_option_with_l
    create_test_files do
      date_str = Time.now.strftime('%_m %_d %H:%M')
      r, w = IO.pipe
      system "ruby #{__dir__}/../ls.rb -l test_file1 test_file2 test_dir test_dir2", out: w
      w.close

      expected = <<~TEXT
        -rw-r--r--  1 #{@user_name}  staff     100 #{date_str} test_file1
        -rw-r--r--  1 #{@user_name}  everyone    0 #{date_str} test_file2

        test_dir:
        total 8
        -rw-r--r--  1 #{@user_name}  everyone  100 #{date_str} test_file3
        -rw-r--r--  1 #{@user_name}  staff       0 #{date_str} test_file4

        test_dir2:
        total 8
        -rw-r--r--  1 #{@user_name}  staff       0 #{date_str} test_file5
        -rw-r--r--  1 #{@user_name}  everyone  100 #{date_str} test_file6
      TEXT

      assert_equal expected, r.gets(nil)
    end
  end

  # aオプションは隠しファイルを表示する
  def test_option_with_a
    create_test_files do
      r, w = IO.pipe
      system "ruby #{__dir__}/../ls.rb -a", out: w
      w.close

      # rubocop:disable Layout/TrailingWhitespace
      expected = <<~TEXT
        .            .test_hidden test_dir2    test_file2  
        ..           test_dir     test_file1  
      TEXT
      # rubocop:enable Layout/TrailingWhitespace

      assert_equal expected, r.gets(nil)
    end
  end

  # rオプションはファイルの並び順を反転する
  def test_option_with_r
    create_test_files do
      r, w = IO.pipe
      system "ruby #{__dir__}/../ls.rb -r test_file1 test_file2 test_dir test_dir2", out: w
      w.close

      expected = <<~TEXT
        test_file2 test_file1

        test_dir2:
        test_file6 test_file5

        test_dir:
        test_file4 test_file3
      TEXT

      assert_equal expected, r.gets(nil)
    end
  end

  # lとrオプションの組み合わせでファイルとディレクトリの並び順を降順にする
  def test_option_with_l_and_r
    create_test_files do
      date_str = Time.now.strftime('%_m %_d %H:%M')
      r, w = IO.pipe
      system "ruby #{__dir__}/../ls.rb -lr test_file1 test_file2 test_dir test_dir2", out: w
      w.close

      expected = <<~TEXT
        -rw-r--r--  1 #{@user_name}  everyone    0 #{date_str} test_file2
        -rw-r--r--  1 #{@user_name}  staff     100 #{date_str} test_file1

        test_dir2:
        total 8
        -rw-r--r--  1 #{@user_name}  everyone  100 #{date_str} test_file6
        -rw-r--r--  1 #{@user_name}  staff       0 #{date_str} test_file5

        test_dir:
        total 8
        -rw-r--r--  1 #{@user_name}  staff       0 #{date_str} test_file4
        -rw-r--r--  1 #{@user_name}  everyone  100 #{date_str} test_file3
      TEXT

      assert_equal expected, r.gets(nil)
    end
  end
end
