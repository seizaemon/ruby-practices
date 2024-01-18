# frozen_string_literal: true

class Frame
  attr_reader :shots

  def initialize
    @shots = { first: nil, second: nil }
  end

  def is_full?
    return true if self.is_strike_at(:first)
    not self.is_included_nil_in_2shot
  end

  def is_strike?
    self.is_strike_at(:first)
  end

  def is_spare?
    return false if self.is_included_nil_in_2shot
    self.total == 10
  end

  def add_shot(shot)
    self.add shot unless self.is_full?
  end

  def total
    @shots.compact.values.sum {|e| e.to_i }
  end

  def shot_in_first
    @shots[:first].to_i
  end

  def shot_by_second
    @shots.slice(:first, :second).values.sum {|e| e.to_i }
  end

  private

  def is_strike_at(at_when)
    not @shots[at_when].nil? and @shots[at_when].is_strike?
  end

  def is_included_nil_in_2shot
    @shots.slice(:first, :second).values.include? nil
  end

  def add(current_shot)
    @shots.each do |k, v|
      if v.nil?
        @shots[k] = current_shot
        break
      end
    end
  end
end

class LastFrame < Frame
  def initialize
    super
    @shots[:third] = nil
  end

  def is_strike?
    super and self.is_strike_at(:second)
  end

  def is_full?
    return false if self.is_included_nil_in_2shot
    return false if self.is_strike? or self.is_spare?
    true
  end

  def add_shot(shot)
    self.add shot unless self.is_full?
  end
end