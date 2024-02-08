# frozen_string_literal: true

module WorkDir
  def with_work_dir(&block)
    Dir.mktmpdir('ls_test-') do |tmp_dir|
      Dir.chdir(tmp_dir, &block)
    end
  end
end
