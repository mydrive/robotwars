require 'rrobots'
require 'byebug'

# Helpers for finding the edges of your robot
module RobotEdgeDetector
  def robot_left_edge
    x - size
  end

  def robot_right_edge
    x + size
  end

  def robot_top_edge
    y - size
  end

  def robot_bottom_edge
    y + size
  end
end

# Helpers to robots direction
module DirectionHelper
  def facing_north?
    heading < 180
  end

  def facing_south?
    heading >= 180
  end

  def facing_east?
    heading >= 270 || heading < 90
  end

  def facing_west?
    heading >= 90 && heading < 270
  end
end

# Helpers to detect battlefield edges
module BattlefieldEdgeDetector
  include RobotEdgeDetector
  NEAR_EDGE_PROXIMITY = 30

  def hit_left_edge?
    robot_left_edge <= 0
  end

  def hit_right_edge?
    robot_right_edge >= battlefield_width
  end

  def near_left_edge?
    robot_left_edge - NEAR_EDGE_PROXIMITY <= 0
  end

  def near_right_edge?
    robot_right_edge + NEAR_EDGE_PROXIMITY >= battlefield_width
  end

  def near_top_edge?
    robot_top_edge - NEAR_EDGE_PROXIMITY <= 0
  end

  def near_bottom_edge?
    robot_bottom_edge + NEAR_EDGE_PROXIMITY >= battlefield_height
  end
end

# This helper provides methods for turning away from the edges
module EdgeAvoidance
  include DirectionHelper
  include BattlefieldEdgeDetector

  def avoid_edges
    case
    when near_right_edge?
      turn_away_from_right
    when near_left_edge?
      turn_away_from_left
    when near_top_edge?
      turn_away_from_top
    when near_bottom_edge?
      turn_away_from_bottom
    end
  end

  def turn_away_from_right
    case
    when facing_north?
      turn(10)
    when facing_south?
      turn(-10)
    end
  end

  def turn_away_from_left
    case
    when facing_north?
      turn(-10)
    when facing_south?
      turn(10)
    end
  end

  def turn_away_from_top
    case
    when facing_east?
      turn(-10)
    when facing_west?
      turn(10)
    end
  end

  def turn_away_from_bottom
    case
    when facing_east?
      turn(10)
    when facing_west?
      turn(-10)
    end
  end
end

# This helper causes your robot to move in a randomised zig zag pattern
module ZigZagMovement
  def setup
    @zig_direction = 1
    @zig_count = 0
    @zig_decision_point_range = 4..20
    @zig_decision_point = rand(@zig_decision_point_range)
    @zig_turn_speed = 10
  end

  # You need to call this method every tick you want to continue zig zagging
  def zig_zag
    setup unless @zig_count

    @zig_count += 1

    if @zig_count >= @zig_decision_point
      @zig_direction *= -1
      @zig_count = 0
      @zig_decision_point = rand @zig_decision_point_range
    end

    turn(@zig_turn_speed * @zig_direction)
  end
end

# Helpers for controlling speed
module CruiseControl
  MAX_SPEED = 8

  def max_speed
    to_speed MAX_SPEED
  end

  def to_speed(target)
    case
    when speed > target
      accelerate(-1)
    when speed < target
      accelerate 1
    end
  end
end

# Fires as much as possible without reaching heat limit
module DistanceBasedFireControl
  HEAT_LIMIT = 3.to_f
  DECAYING_RANGE_LIMIT = 1000.to_f

  def fire_limiting_heat(target_distance)
    fire choose_shot_power target_distance
  end

  def choose_shot_power(target_distance)
    case target_distance
    when 0.0..DECAYING_RANGE_LIMIT then calculate_decaying_power target_distance
    else 0.1
    end
  end

  def calculate_decaying_power(target_distance)
    HEAT_LIMIT - (target_distance * (HEAT_LIMIT / DECAYING_RANGE_LIMIT))
  end
end

# Jonny Robot class
class Jonny
  include Robot
  include EdgeAvoidance
  include ZigZagMovement
  include CruiseControl
  include DistanceBasedFireControl

  def initialize
    @max_speed = 8
  end

  def tick(events)
    puts events unless events.empty?
    max_speed
    change_heading
    process_events
  end

  def change_heading
    avoid_edges || zig_zag
  end

  def process_events
    process_scans
    process_hits
    process_broadcasts
  end

  def process_scans
    robots_spotted(events['robot_scanned']) if events.include? 'robot_scanned'
  end

  def process_hits
    been_hit(events['got_hit']) if events.include? 'got_hit'
  end

  def process_broadcasts
    broadcasts_received(events['broadcasts']) if events.include? 'broadcasts'
  end

  def robots_spotted(targets)
    fire_limiting_heat select_target_from targets
  end

  def been_hit(_hits)
    say 'Ow, you bastard!'
  end

  def broadcasts_received(broadcasts)
    broadcasts.each do |broadcast|
      puts "Broadcast Received: #{broadcast}"
    end
  end

  def select_target_from(targets)
    case targets.size
    when 1
      targets.first
    else
      choose_closest_target targets
    end
  end

  def choose_closest_target(targets)
    targets.flatten.min
  end

  # def choose_closest_to_current_heading(target_bearings)
  #   target_bearings.inject(361) do |memo, target_bearing|
  #     difference = (((360 + gun_heading) - target_bearing.first) % 360).abs
  #     if difference < memo
  #       difference
  #     else
  #       memo
  #     end
  #   end
  # end
end
