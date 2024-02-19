# frozen_string_literal: true

require 'pathname'
require_relative 'file_entry'

class EntryList
  include File::Constants
  attr_reader :entries

  def initialize(path = '.', hidden: false, reverse: false)
    @entries = []
    get_entry_list(path, hidden:, reverse:)
  end

  def length
    @entries.length
  end

  def nlink_max_char
    @entries.map { |entry| entry.nlink.to_s.length }.max
  end

  def owner_max_char
    @entries.map { |entry| entry.owner.length }.max
  end

  def group_max_char
    @entries.map { |entry| entry.group.length }.max
  end

  def size_max_char
    @entries.map { |entry| entry.size.to_s.length }.max
  end

  def update_time_max_char
    @entries.map { |entry| entry.update_time.length }.max
  end

  def filename_max_char
    @entries.map { |entry| entry.name.length }.max
  end

  private

  def get_entry_list(path, hidden: false, reverse: false)
    hidden_flag = hidden ? File::FNM_DOTMATCH : 0
    first_entry = FileEntry.new(path)

    if first_entry.type == 'd'
      entries = Pathname.glob('**', hidden_flag, base: path)
      entries.map! { |entry| (Pathname.new(path) + entry).to_s }
    else
      entries = Dir.glob(path, hidden_flag)
    end
    entries << '..' if hidden
    @entries = reverse ? bulk_create_entry(entries.sort.reverse) : bulk_create_entry(entries.sort)
  end

  def bulk_create_entry(entries)
    entries.map { |entry| FileEntry.new(entry) }
  end
end
