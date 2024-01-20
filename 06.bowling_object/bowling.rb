#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/game'
require_relative 'lib/frame'
require_relative 'lib/shot'

game = Game.new
score_history = ARGV[0].split(',')

9.times do
  frame = Frame.new
  until frame.is_full?
    frame.add_shot Shot.new(score_history.shift)
  end
  game.add_frame frame
end

last_frame = LastFrame.new
until last_frame.is_full?
  last_frame.add_shot Shot.new(score_history.shift)
end
game.add_frame last_frame

puts game.score
