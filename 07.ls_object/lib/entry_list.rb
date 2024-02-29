# frozen_string_literal: true

require 'pathname'
require_relative 'file_entry'

class EntryList
  include File::Constants
  attr_reader :entries, :files, :dirs, :no_existence

  def initialize(file_names, base: '', reverse: false)
    @entries = []
    @no_existence = []
    @files = []
    @dirs = []
    create_entries(file_names, base:, reverse:)
  end

  def empty?
    @entries.empty?
  end

  def length
    @entries.length
  end

  def nlink_max_char
    @entries.map { |entry|entry.nlink.to_s.length }.max
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

  def create_entries(file_names, base:, reverse:)
    @entries = reverse ? bulk_create_entry(file_names.sort.reverse, base) : bulk_create_entry(file_names.sort, base)
  end

  def bulk_create_entry(entries, base)
    entries.map do |entry|
      f = FileEntry.new((Pathname(base) + entry).to_s)
      f.type == 'd' ? @dirs << entry : @files << entry
      f
    rescue Errno::ENOENT
      @no_existence << entry
    end
  end
end
