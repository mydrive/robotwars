require 'rrobots'
require 'byebug'

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

  # def facing_north?
  #   heading >= 45 && heading < 135
  # end

  # def facing_south?
  #   heading >= 225 && heading < 315
  # end

  # def facing_east?
  #   heading >= 315 || heading < 45
  # end

  # def facing_west
  #   heading >= 135 && heading < 225
  # end
end

# Helpers to detect battlefield edges
module BattlefieldEdgeDetector
  def hit_left_edge?
    robot_left_edge <= 0
  end

  def hit_right_edge?
    robot_right_edge >= battlefield_width
  end

  def near_left_edge?
    robot_left_edge - @near_edge_proximity <= 0
  end

  def near_right_edge?
    robot_right_edge + @near_edge_proximity >= battlefield_width
  end

  def near_top_edge?
    robot_top_edge - @near_edge_proximity <= 0
  end

  def near_bottom_edge?
    robot_bottom_edge + @near_edge_proximity >= battlefield_height
  end
end

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

# Jonny Robot class
# How will it perform.....
# .....poorly!
class Jonny
  include Robot
  include DirectionHelper
  include BattlefieldEdgeDetector
  include RobotEdgeDetector

  def initialize
    @zig_direction = 1
    @zig_count = 0
    @zig_decision_point_range = 4..20
    @zig_decision_point = rand(@zig_decision_point_range)
    @turn_speed = 10
    @near_edge_proximity = 30
    @max_speed = 8
  end

  def tick(events)
    puts events
    puts "Gun Heading #{gun_heading}"
    # zig_zag
    rotate
    to_speed @max_speed
  end

  def to_speed(target)
    case
    when speed > target
      accelerate(speed - 1)
    when speed < target
      accelerate(speed + 1)
    end
  end

  def rotate
    case
    when near_right_edge?
      turn_away_from_right
    when near_left_edge?
      turn_away_from_left
    when near_top_edge?
      turn_away_from_top
    when near_bottom_edge?
      turn_away_from_bottom
    else
      zig_zag
    end
  end

  def zig_zag
    @zig_count += 1

    if @zig_count >= @zig_decision_point
      @zig_direction *= -1
      @zig_count = 0
      @zip_decision_point = rand @zig_decision_point_range
    end

    turn(@turn_speed * @zig_direction)
  end

  private

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
