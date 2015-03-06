require 'rrobots'
require 'byebug'

# Jonny Robot class
# How will it perform.....
# .....poorly!
class Jonny
  include Robot

  def initialize
    @zig_direction = 1
    @zig_count = 0
    @zig_decision_point = 8
    @turn_speed = 10
    @near_edge_proximity = 80
  end

  def tick(events)
    puts events
    # zig_zag
    rotate
    to_speed 4
  end

  def to_speed(target)
    case
    when speed > target
      accelerate(speed + 1)
    when speed < target
      accelerate(speed - 1)
    end
  end

  def rotate
    # turn(@turn_speed * @zig_direction)
  end

  def zig_zag
    @zig_count += 1

    if @zig_count >= @zig_decision_point
      @zig_direction *= -1
      @zig_count = 0
    end
  end

  private

  def hit_left_edge
    left_edge <= 0
  end

  def hit_right_edge
    right_edge >= battlefield_width
  end

  def near_left_edge
    left_edge - @near_edge_proximity <= 0
  end

  def near_right_edge
    right_edge + @near_edge_proximity >= battlefield_width
  end

  def left_edge
    x - size
  end

  def right_edge
    x + size
  end

  def top_edge
    y - size
  end

  def bottom_edge
    y + size
  end

  def facing_north?
    heading >= 45 && heading < 135
  end

  def facing_south?
    heading >= 225 && heading < 315
  end

  def facing_east?
    heading >= 315 || heading < 45
  end

  def facing_west
    heading >= 135 && heading < 225
  end
end
