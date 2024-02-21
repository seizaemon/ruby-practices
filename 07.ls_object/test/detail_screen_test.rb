# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/detail_screen'
require_relative '../lib/entry_list'
require_relative './work_dir'
require 'io/console/size'
require 'time'

class DetailScreenTest < Minitest::Test
  include WorkDir
  def setup
    _, @console_width = IO.console_size
    @user_name = Etc.getpwuid(Process::UID.rid).name
    @group_name = Etc.getgrgid(Process::GID.rid).name
  end

  # detailscreenはファイルの詳細情報を一列で表示する
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
      screen = DetailScreen.new(EntryList.new(%w[test_file2 test_file1 test_long_file1]))
      r, w = IO.pipe
      w.puts screen.out
      w.close
      assert_equal expected, r.gets('')
    end
  end
end
