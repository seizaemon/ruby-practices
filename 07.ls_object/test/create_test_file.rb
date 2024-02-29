# frozen_string_literal: true

module CreateTestFile
  def create_various_type_of_file
    system 'touch test_file ; chmod 765 test_file ; touch test_file2 ; chmod 421 test_file2 ; touch test_file3 ; chmod 000 test_file3'
    system 'touch test_file4 ; chmod 4777 test_file4 ; touch test_file5 ; chmod 4666 test_file5'
    system 'touch test_file6 ; chmod 2777 test_file6 ; touch test_file7 ; chmod 2666 test_file7'
  end

  def filename_with_owner_and_group
    system 'touch test_file'
    out = ['id -un', 'id -gn'].map do |cmd|
      element = ''
      IO.pipe do |r, w|
        system cmd, out: w
        element = r.gets.chomp
      end
      element
    end
    ['test_file', out].flatten
  end
end
