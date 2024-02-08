# frozen_string_literal: true

require_relative 'file_entry'

module FileEntryFactory
  def create_file_entries(entries)
    entries.map { |entry| FileEntry.new(entry) }
  end
end