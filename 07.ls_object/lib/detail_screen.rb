# frozen_string_literal: true

class DetailScreen
  def initialize(entry_list)
    @entry_list = entry_list
  end

  def out
    fmt = "%1s%8s  % #{@entry_list.nlink_max_char}s " \
      +"% #{@entry_list.owner_max_char}s  " \
      +"% #{@entry_list.group_max_char}s  " \
      +"% #{@entry_list.size_max_char}s " \
      +"% #{@entry_list.update_time_max_char}s " \
      +"%-#{@entry_list.filename_max_char}s"
    @entry_list.entries.map do |entry|
      format fmt, entry.type, entry.permission, entry.nlink, entry.owner, entry.group, entry.size, entry.update_time, entry.name
    end.join("\n")
  end
end
