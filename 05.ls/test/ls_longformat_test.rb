#!/usr/bin/env ruby

# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/ls'
require_relative './test_tools'
require 'pathname'
require 'etc'

# To do
# symlinkのテスト
# -a -r オプションのテスト
# ファイルとディレクトリを複数指定した時のテスト

class LsSimpleTest < Minitest::Test
  def setup
    @test_tools = TestToolsLongFormat.new
    @test_ls = LsLong.new
    @test_ls.entries = ["#{@test_tools.test_dir}/"]
    @my_user = Etc.getpwuid(Process.euid).name
    @my_group = Etc.getgrgid(Process.egid).name
  end

  def test_one_file_with_ascii_name
    perm_tested = {
      0o770 => '---',
      0o771 => '--x',
      0o772 => '-w-',
      0o773 => '-wx',
      0o774 => 'r--',
      0o775 => 'r-x',
      0o776 => 'rw-',
      0o777 => 'rwx'
    }
    perm_tested.each do |perm_octet, mode_str|
      ctime = @test_tools.create_tmp_file_with_ctime(1, perm: perm_octet)
      expected = <<~TEXT
        -rwxrwx#{mode_str}  1 #{@my_user}  #{@my_group}  0 #{ctime[0]} #{@test_tools.test_dir}/test_file1
      TEXT
      @test_ls.entries = ["#{@test_tools.test_dir}/test_file1"]
      assert_equal expected, @test_tools.capture_stdout(@test_ls)
      @test_tools.remove_entries(['test_file1'])
    end
  end

  def test_one_dir_with_ascii_name
    perm_tested = {
      0o770 => '---',
      0o771 => '--x',
      0o772 => '-w-',
      0o773 => '-wx',
      0o774 => 'r--',
      0o775 => 'r-x',
      0o776 => 'rw-',
      0o777 => 'rwx'
    }
    perm_tested.each do |perm_octet, mode_str|
      ctime = @test_tools.create_tmp_dir_with_ctime(1, perm: perm_octet)
      expected = <<~TEXT
        drwxrwx#{mode_str}  2 #{@my_user}  #{@my_group}  64 #{ctime[0]} #{@test_tools.test_dir}/test_dir1
      TEXT
      @test_ls.entries = ["#{@test_tools.test_dir}/test_dir1"]
      assert_equal expected, @test_tools.capture_stdout(@test_ls)
      @test_tools.remove_entries(['test_dir1'])
    end
  end

  def teardown
    @test_tools.cleanup
  end
end

class LsMultipleEntriesTest < Minitest::Test
  def setup
    @test_tools = TestToolsLongFormat.new
    @test_ls = LsLong.new
    @test_ls.entries = ["#{@test_tools.test_dir}/"]
    @my_user = Etc.getpwuid(Process.euid).name
    @my_group = Etc.getgrgid(Process.egid).name
  end

  def test_many_files
    perm_octet = 0o744
    ctimes = @test_tools.create_tmp_file_with_ctime(3, perm: perm_octet)
    expected1 = <<~TEXT
      total 0
      -rwxr--r--  1 #{@my_user}  #{@my_group}  0 #{ctimes[0]} test_file1
      -rwxr--r--  1 #{@my_user}  #{@my_group}  0 #{ctimes[1]} test_file2
      -rwxr--r--  1 #{@my_user}  #{@my_group}  0 #{ctimes[2]} test_file3
    TEXT
    assert_equal expected1, @test_tools.capture_stdout(@test_ls)
  end

  def test_many_dirs
    perm_octet = 0o744
    ctimes = @test_tools.create_tmp_dir_with_ctime(3, perm: perm_octet)
    expected1 = <<~TEXT
      total 0
      drwxr--r--  2 #{@my_user}  #{@my_group}  64 #{ctimes[0]} test_dir1
      drwxr--r--  2 #{@my_user}  #{@my_group}  64 #{ctimes[1]} test_dir2
      drwxr--r--  2 #{@my_user}  #{@my_group}  64 #{ctimes[2]} test_dir3
    TEXT
    assert_equal expected1, @test_tools.capture_stdout(@test_ls)
  end

  def test_mix_entries
    perm_octet = 0o744
    ctime_files = @test_tools.create_tmp_file_with_ctime(3, perm: perm_octet)
    ctime_dirs = @test_tools.create_tmp_dir_with_ctime(3, perm: perm_octet)
    expected1 = <<~TEXT
      total 0
      drwxr--r--  2 #{@my_user}  #{@my_group}  64 #{ctime_dirs[0]} test_dir1
      drwxr--r--  2 #{@my_user}  #{@my_group}  64 #{ctime_dirs[1]} test_dir2
      drwxr--r--  2 #{@my_user}  #{@my_group}  64 #{ctime_dirs[2]} test_dir3
      -rwxr--r--  1 #{@my_user}  #{@my_group}   0 #{ctime_files[0]} test_file1
      -rwxr--r--  1 #{@my_user}  #{@my_group}   0 #{ctime_files[1]} test_file2
      -rwxr--r--  1 #{@my_user}  #{@my_group}   0 #{ctime_files[2]} test_file3
    TEXT
    assert_equal expected1, @test_tools.capture_stdout(@test_ls)
  end

  def teardown
    @test_tools.cleanup
  end
end

class LsMultipleArgsTest < Minitest::Test
  def setup
    @test_tools = TestToolsLongFormat.new
    @test_ls = LsLong.new
    @test_ls.entries = ["#{@test_tools.test_dir}/"]
    @my_user = Etc.getpwuid(Process.euid).name
    @my_group = Etc.getgrgid(Process.egid).name
  end

  def test_mixargs
    ctime_file = @test_tools.create_tmp_file_with_ctime(1)
    @test_tools.create_tmp_dirs(1)
    ctimes_in_subdir = @test_tools.create_tmp_file_with_ctime(2, sub_dir: 'test_dir1')
    expected1 = <<~TEXT
      -rw-r--r--  1 #{@my_user}  #{@my_group}  0 #{ctime_file[0]} #{@test_tools.test_dir}/test_file1

      #{@test_tools.test_dir}/test_dir1/:
      total 0
      -rw-r--r--  1 #{@my_user}  #{@my_group}  0 #{ctimes_in_subdir[0]} test_file1
      -rw-r--r--  1 #{@my_user}  #{@my_group}  0 #{ctimes_in_subdir[1]} test_file2
    TEXT
    @test_ls.entries = [
      "#{@test_tools.test_dir}/test_file1",
      "#{@test_tools.test_dir}/test_dir1/"
    ]
    assert_equal expected1, @test_tools.capture_stdout(@test_ls)
  end

  def teardown
    @test_tools.cleanup
  end
end

class LsWithAllOptionTest < Minitest::Test
  def setup
    @test_tools = TestToolsLongFormat.new
    @test_ls = LsLong.new(['SHOW_DOTMATCH'])
    @test_ls.entries = ["#{@test_tools.test_dir}/"]
    @my_user = Etc.getpwuid(Process.euid).name
    @my_group = Etc.getgrgid(Process.egid).name
  end

  def test_one_hiddenfile_with_japanese_name
    ctimes_current = @test_tools.create_tmp_dir_with_ctime(1)
    ctimes = @test_tools.create_tmp_file_with_ctime(1, is_hidden: true, sub_dir: 'test_dir1')
    expected1 = <<~TEXT
      total 0
      drwxrwxrwx  3 #{@my_user}  #{@my_group}  96 #{ctimes_current[0]} .
      -rw-r--r--  1 #{@my_user}  #{@my_group}   0 #{ctimes[0]} .test_file1
    TEXT
    @test_ls.entries = ["#{@test_tools.test_dir}/test_dir1/"]
    assert_equal expected1, @test_tools.capture_stdout(@test_ls)
  end

  def teardown
    @test_tools.cleanup
  end
end

class LsWithROptionTest < Minitest::Test
  def setup
    @test_tools = TestToolsLongFormat.new
    @test_ls = LsLong.new(['SORT_REVERSE'])
    @test_ls.entries = ["#{@test_tools.test_dir}/"]
    @my_user = Etc.getpwuid(Process.euid).name
    @my_group = Etc.getgrgid(Process.egid).name
  end

  def test_files_and_dirs
    ctimes_current = @test_tools.create_tmp_file_with_ctime(2)
    @test_tools.create_tmp_dirs(2)
    ctimes_subdir = @test_tools.create_tmp_file_with_ctime(2, sub_dir: 'test_dir1')
    ctimes_subdir2 = @test_tools.create_tmp_file_with_ctime(2, sub_dir: 'test_dir2')
    expected1 = <<~TEXT
      -rw-r--r--  1 #{@my_user}  #{@my_group}  0 #{ctimes_current[0]} #{@test_tools.test_dir}/test_file2
      -rw-r--r--  1 #{@my_user}  #{@my_group}  0 #{ctimes_current[0]} #{@test_tools.test_dir}/test_file1

      #{@test_tools.test_dir}/test_dir2/:
      total 0
      -rw-r--r--  1 #{@my_user}  #{@my_group}  0 #{ctimes_subdir2[0]} test_file2
      -rw-r--r--  1 #{@my_user}  #{@my_group}  0 #{ctimes_subdir2[0]} test_file1

      #{@test_tools.test_dir}/test_dir1/:
      total 0
      -rw-r--r--  1 #{@my_user}  #{@my_group}  0 #{ctimes_subdir[0]} test_file2
      -rw-r--r--  1 #{@my_user}  #{@my_group}  0 #{ctimes_subdir[0]} test_file1
    TEXT
    @test_ls.entries = [
      "#{@test_tools.test_dir}/test_dir1/", "#{@test_tools.test_dir}/test_dir2/",
      "#{@test_tools.test_dir}/test_file1", "#{@test_tools.test_dir}/test_file2"
    ]
    assert_equal expected1, @test_tools.capture_stdout(@test_ls)
  end

  def teardown
    @test_tools.cleanup
  end
end

class LsWithAWithROptionTest < Minitest::Test
  def setup
    @test_tools = TestToolsLongFormat.new
    @test_ls = LsLong.new(%w[SHOW_DOTMATCH SORT_REVERSE])
    @test_ls.entries = ["#{@test_tools.test_dir}/"]
    @my_user = Etc.getpwuid(Process.euid).name
    @my_group = Etc.getgrgid(Process.egid).name
  end

  def test_multiple_arg_withoption
    ctimes_hiddentestdir = @test_tools.create_tmp_dir_with_ctime(1, is_hidden: true)
    ctimes_files = @test_tools.create_tmp_file_with_ctime(2)
    ctimes_hiddenfiles = @test_tools.create_tmp_file_with_ctime(2, is_hidden: true)

    ctimes_files_in_hiddendir = @test_tools.create_tmp_file_with_ctime(2, sub_dir: '.test_dir1')
    ctimes_hiddenfiles_in_hiddendir = @test_tools.create_tmp_file_with_ctime(1, is_hidden: true, sub_dir: '.test_dir1')

    expected1 = <<~TEXT
      -rw-r--r--  1 #{@my_user}  #{@my_group}  0 #{ctimes_files[1]} #{@test_tools.test_dir}/test_file2
      -rw-r--r--  1 #{@my_user}  #{@my_group}  0 #{ctimes_files[0]} #{@test_tools.test_dir}/test_file1
      -rw-r--r--  1 #{@my_user}  #{@my_group}  0 #{ctimes_hiddenfiles[0]} #{@test_tools.test_dir}/.test_file1

      #{@test_tools.test_dir}/.test_dir1/:
      total 0
      -rw-r--r--  1 #{@my_user}  #{@my_group}    0 #{ctimes_files_in_hiddendir[1]} test_file2
      -rw-r--r--  1 #{@my_user}  #{@my_group}    0 #{ctimes_files_in_hiddendir[0]} test_file1
      -rw-r--r--  1 #{@my_user}  #{@my_group}    0 #{ctimes_hiddenfiles_in_hiddendir[0]} .test_file1
      drwxrwxrwx  5 #{@my_user}  #{@my_group}  160 #{ctimes_hiddentestdir[0]} .
    TEXT
    @test_ls.entries = [
      "#{@test_tools.test_dir}/.test_dir1/",
      "#{@test_tools.test_dir}/test_file1", "#{@test_tools.test_dir}/test_file2", "#{@test_tools.test_dir}/.test_file1"
    ]
    assert_equal expected1, @test_tools.capture_stdout(@test_ls)
  end

  def teardown
    @test_tools.cleanup
  end
end

class LsSpecialFileTest < Minitest::Test
  # todo
  # ブロックデバイス（キャラクタ・ブロック）のテスト
  def setup
    @test_tools = TestToolsLongFormat.new
    @test_ls = LsLong.new
    @test_ls.entries = ["#{@test_tools.test_dir}/"]
    @my_user = Etc.getpwuid(Process.euid).name
    @my_group = Etc.getgrgid(Process.egid).name
  end

  def test_symbolic_link
    ctime = @test_tools.create_tmp_file_with_ctime(1)
    File.symlink("#{@test_tools.test_dir}/test_file1", "#{@test_tools.test_dir}/test_link")
    ctime_symlink = Time.now.strftime('%_m %d %H:%M').to_s
    expected1 = <<~TEXT
      total 0
      -rw-r--r--  1 #{@my_user}  #{@my_group}   0 #{ctime[0]} test_file1
      lrwxrwxrwx  1 #{@my_user}  #{@my_group}  82 #{ctime_symlink} test_link -> #{@test_tools.test_dir}/test_file1
    TEXT
    assert_equal expected1, @test_tools.capture_stdout(@test_ls)
  end

  def test_setuid
    ctime = @test_tools.create_tmp_file_with_ctime(2)
    FileUtils.chmod('u+s', "#{@test_tools.test_dir}/test_file1")
    FileUtils.chmod('u+sx', "#{@test_tools.test_dir}/test_file2")
    expected1 = <<~TEXT
      total 0
      -rwSr--r--  1 #{@my_user}  #{@my_group}  0 #{ctime[0]} test_file1
      -rwsr--r--  1 #{@my_user}  #{@my_group}  0 #{ctime[0]} test_file2
    TEXT
    assert_equal expected1, @test_tools.capture_stdout(@test_ls)
  end

  def test_setgid
    ctime = @test_tools.create_tmp_file_with_ctime(2)
    FileUtils.chmod('g+s', "#{@test_tools.test_dir}/test_file1")
    FileUtils.chmod('g+sx', "#{@test_tools.test_dir}/test_file2")
    expected1 = <<~TEXT
      total 0
      -rw-r-Sr--  1 #{@my_user}  #{@my_group}  0 #{ctime[0]} test_file1
      -rw-r-sr--  1 #{@my_user}  #{@my_group}  0 #{ctime[0]} test_file2
    TEXT
    assert_equal expected1, @test_tools.capture_stdout(@test_ls)
  end

  def test_sticky
    ctime = @test_tools.create_tmp_file_with_ctime(2)
    FileUtils.chmod('o+t', "#{@test_tools.test_dir}/test_file1")
    FileUtils.chmod('o+tx', "#{@test_tools.test_dir}/test_file2")
    expected1 = <<~TEXT
      total 0
      -rw-r--r-T  1 #{@my_user}  #{@my_group}  0 #{ctime[0]} test_file1
      -rw-r--r-t  1 #{@my_user}  #{@my_group}  0 #{ctime[0]} test_file2
    TEXT
    assert_equal expected1, @test_tools.capture_stdout(@test_ls)
  end

  def test_fifo
    ctime = @test_tools.make_fifo
    expected1 = <<~TEXT
      total 0
      prw-rw-rw-  1 #{@my_user}  #{@my_group}  0 #{ctime} test_fifo
    TEXT
    assert_equal expected1, @test_tools.capture_stdout(@test_ls)
  end

  def test_blk_file
    @test_ls.entries = ['/dev/disk0']
    assert_equal @test_tools.ref_blk_file, @test_tools.capture_stdout(@test_ls)
  end

  def test_char_file
    @test_ls.entries = ['/dev/zero']
    assert_equal @test_tools.ref_char_file, @test_tools.capture_stdout(@test_ls)
  end

  def test_socket_file
    @test_ls.entries = ['/var/run/mDNSResponder']
    assert_equal @test_tools.ref_socket_file, @test_tools.capture_stdout(@test_ls)
  end

  def test_file_with_xattr
    @test_ls.entries = ['/var/run/utmpx']
    assert_equal @test_tools.ref_xattr_file, @test_tools.capture_stdout(@test_ls)
  end

  def teardown
    @test_tools.cleanup
  end
end
