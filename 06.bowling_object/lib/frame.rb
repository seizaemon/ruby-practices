# frozen_string_literal: true

class Frame
  attr_reader :shots

  def initialize
    @shots = { first: nil, second: nil }
  end

  def is_full?
    return true if self.is_strike?
    # これもリファクタできそう
    not @shots.slice(:first, :second).values.include? nil
  end

  def is_strike?
    self.is_strike_at_shot?(:first)
  end

  def is_spare?
    return false if @shots.slice(:first, :second).values.include? nil
    self.total_pins == 10
  end

  def add_shot(shot)
    self.add shot unless self.is_full?
  end

  def total_pins
    @shots.compact.values.map do |shot|
      return 10 if shot.is_strike?
      shot.pins
    end.sum
  end

  private

  def is_strike_at_shot?(at_when)
    not @shots[at_when].nil? and @shots[at_when].is_strike?
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
    super and self.is_strike_at_shot?(:second)
  end

  def is_full?
    return false if @shots.slice(:first, :second).values.include? nil
    return false if self.is_strike? or self.is_spare?
    true
  end

  def add_shot(shot)
    self.add shot unless self.is_full?
  end
end