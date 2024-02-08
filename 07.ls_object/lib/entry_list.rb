# frozen_string_literal: true

require_relative 'file_entry_factory'

class EntryList
  include File::Constants
  include FileEntryFactory
  attr_reader :entries

  def initialize(path = '.', hidden: false, reverse: false, recurse: false)
    @entries = []
    get_entry_list(path, hidden:, reverse:, recurse:)
  end

  private

  def get_entry_list(path, hidden: false, reverse: false, recurse: false)
    hidden_flag = hidden ? File::FNM_DOTMATCH : 0
    pattern = recurse ? '**' : '*'
    entries = Dir.glob(pattern, hidden_flag, base: path)
    entries << '..' if hidden
    @entries = reverse ? create_file_entries(entries.sort.reverse) : create_file_entries(entries.sort)
  end
end