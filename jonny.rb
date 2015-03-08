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
  def zig_zag_setup
    @zig_direction = 1
    @zig_count = 0
    @zig_decision_point_range = 4..20
    @zig_decision_point = rand(@zig_decision_point_range)
    @zig_turn_speed = 10
  end

  # You need to call this method every tick you want to continue zig zagging
  def zig_zag
    zig_zag_setup unless @zig_count

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
    # byebug
    @gun_target_bearing ||= 0
    @previous_gun_bearing ||= gun_heading

    gun_bearing_correction = bearing_correction(gun_heading, @gun_target_bearing, heading_change)

    turn_gun gun_bearing_correction

    gun_moved = (gun_heading - @previous_gun_bearing) % 360

    gun_end_of_tick_cleanup

    gun_moved
  end

  def gun_end_of_tick_cleanup
    puts "Gun Heading #{gun_heading}"
    @previous_gun_bearing = gun_heading
  end

  def spin_gun(increment)
    @gun_target_bearing ||= 0

    @gun_target_bearing = (@gun_target_bearing + increment) % 360
  end
end

# Provides helpful radar scanning methods
module RadarScanner
  include BearingDifferentialEngine

  SEARCH_BANDS = [60, 40, 20, 10]

  def radar_scanner_setup
    @radar_target_bearing ||= 0
    @previous_radar_bearing ||= radar_heading
    @radar_search_band ||= 0
    @radar_search_direction ||= 1
    @target_spotted_previous_sweep ||= false
    @target_spotted_this_sweep ||= false
  end

  def align_radar(heading_change)
    radar_scanner_setup if @radar_target_bearing.nil?

    new_radar_heading = bearing_correction(radar_heading, @radar_target_bearing, heading_change)

    turn_radar new_radar_heading

    #puts "RADAR: PR[#{@previous_radar_bearing}] CR[#{radar_heading}] NB[#{new_radar_heading}]"

    radar_end_of_tick_cleanup
  end

  def radar_end_of_tick_cleanup
    puts "Radar Heading #{radar_heading}"
    @target_spotted_previous_sweep = @target_spotted_this_sweep
    @target_spotted_this_sweep = false
    @previous_radar_bearing = radar_heading
  end

  def spin_radar(increment)
    @radar_target_bearing ||= 0

    @radar_target_bearing = (@radar_target_bearing + increment) % 360
  end

  def scan_for_target
    unless @target_spotted_previous_sweep || @target_spotted_this_sweep
      target_lost
      return
    end

    case
    when @target_spotted_this_sweep
      narrow_search
    when @target_spotted_previous_sweep
      puts 'NOT THIS TIME'
    end
  end

  def targets_sighted(_targets)
    puts "ROBOT SPOTTED!!! R1[#{@previous_radar_bearing}] R2[#{radar_heading}]"
    @target_spotted_this_sweep = true
  end

  def narrow_search
    @radar_search_direction *= -1
    @radar_search_band += 1 if @radar_search_band < (SEARCH_BANDS.size - 1)

    puts "SEARCH BAND #{@radar_search_band}"

    spin_radar(radar_heading + (SEARCH_BANDS[@radar_search_band] * @radar_search_direction))
  end

  def target_lost
    puts "Target Lost"
    @radar_search_direction = 1
    @radar_search_band = 0

    spin_radar(radar_heading + (SEARCH_BANDS[@radar_search_band] * @radar_search_direction))
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
  include RadarScanner

  def tick(_events)
    max_speed
    process_events
    heading_difference = change_heading
    spin_gun 1.5
    # scan_for_target
    byebug

    gun_heading_difference = align_gun heading_difference

    align_radar(gun_heading_difference)
    # fire 0.1
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
    targets_sighted targets
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
