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
    heading_change =
      case
      when facing_north? then 10
      when facing_south? then -10
      end

    turn heading_change
    heading_change
  end

  def turn_away_from_left
    heading_change =
      case
      when facing_north?
        turn(-10)
      when facing_south?
        turn(10)
      end

    turn heading_change
    heading_change
  end

  def turn_away_from_top
    heading_change =
      case
      when facing_east?
        turn(-10)
      when facing_west?
        turn(10)
      end

    turn heading_change
    heading_change
  end

  def turn_away_from_bottom
    heading_change =
      case
      when facing_east?
        turn(10)
      when facing_west?
        turn(-10)
      end

    turn heading_change
    heading_change
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

    heading_change = @zig_turn_speed * @zig_direction

    turn heading_change
    heading_change
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
  MINIMUM_POWER = 0.5

  def fire_limiting_heat(target_distance)
    fire choose_shot_power target_distance
  end

  def choose_shot_power(target_distance)
    case target_distance
    when 0.0..DECAYING_RANGE_LIMIT then calculate_decaying_power target_distance
    else MINIMUM_POWER
    end
  end

  def calculate_decaying_power(target_distance)
    power = HEAT_LIMIT - (target_distance * (HEAT_LIMIT / DECAYING_RANGE_LIMIT))
    power < MINIMUM_POWER ? MINIMUM_POWER : power
  end
end

# Helps calculate bearing differences
module BearingDifferentialEngine
  def bearing_correction(from, to, heading_change)
    bearing_difference(from, to) - heading_change
  end

  def bearing_difference(from, to)
    difference = to - from
    difference += 360 if difference.abs > 180
    difference
  end
end

# Keeps the gun pointing on a single bearing
module FixedGunDirection
  include BearingDifferentialEngine

  def align_gun(heading_change)
    @gun_target_bearing ||= 0

    gun_bearing_correction = bearing_correction(gun_heading, @gun_target_bearing, heading_change)

    turn_gun gun_bearing_correction

    gun_bearing_correction
  end

  def spin_gun(increment)
    @gun_target_bearing ||= 0

    @gun_target_bearing = (@gun_target_bearing + increment) % 360
  end
end

# Provides helpful radar scanning methods
module RadarScanner
  include BearingDifferentialEngine

  def align_radar(heading_change)
    @radar_target_bearing ||= 0

    turn_radar bearing_correction(radar_heading, @radar_target_bearing, (heading_change * -1))
  end
end

# Jonny Robot class
class Jonny
  include Robot
  include EdgeAvoidance
  include ZigZagMovement
  include CruiseControl
  include DistanceBasedFireControl
  include FixedGunDirection

  def tick(_events)
    max_speed
    process_events
    heading_difference = change_heading
    align_gun heading_difference
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

  def broadcasts_received(_broadcasts)
    # broadcasts.each do |broadcast|
    #   puts "Broadcast Received: #{broadcast}"
    # end
  end

  def select_target_from(targets)
    case targets.size
    when 1
      targets.flatten.first
    else
      choose_closest_target targets
    end
  end

  def choose_closest_target(targets)
    targets.flatten.min
  end
end
