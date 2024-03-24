# frozen_string_literal: true

require 'pathname'

module EntriesHelper
  def nlink_max_char(entries)
    entries.map { |entry| entry.nlink.to_s.length }.max
  end

  def owner_max_char(entries)
    entries.map { |entry| entry.owner.length }.max
  end

  def group_max_char(entries)
    entries.map { |entry| entry.group.length }.max
  end

  def size_max_char(entries)
    entries.map { |entry| entry.size.to_s.length }.max
  end

  def update_time_max_char(entries)
    entries.map { |entry| entry.update_time.length }.max
  end

  def filename_max_char(entries)
    entries.map { |entry| entry.name.length }.max
  end

  def total_blocks(entries)
    entries.sum(&:blocks)
  end
end
