require 'rrobots'

class Mike
  include Robot

  @@last_pain = nil
  @@pain_counter = 0
  @@turn_direction = 1
  @@turn_speed = rand(1..8)

  def tick events
    setup
    trash_talk
    pain
    accelerate 8
    test_and_fire
    turn @@turn_speed * @@turn_direction
  end

  def setup
    turn_radar 1 if time < 2
    broadcast 'Come get some!'
    turn_gun 30 if time < 3
    new_turn_direction = (time / 1000).round.even? ? 1 : -1
    @@turn_speed = rand(1..8) if new_turn_direction != @@turn_direction
    @@turn_direction =  new_turn_direction
  end

  def trash_talk
    case time
    when lt(100)
      say "I've calculated your chance of survival"
    when lt(200)
      say "but I don't think you'll like it."
    end
  end


  def test_and_fire
    if seen_one?
      hes_close ? fire(3) : fire(2)
      turn_gun -1
    else
      centre_gun
    end
  end

  def centre_gun
    difference = heading + @@turn_direction * 90 - gun_heading
    turn_gun difference
  end

  def random_turn_speed

  end

  private

  def hes_close
    events['robot_scanned'].first.first < 1000
  end

  def seen_one?
    !events['robot_scanned'].empty?
  end

  def lt(number)
    lambda{|n| n < number }
  end

  def pain
    if !@@last_pain.nil?
      if @@pain_counter < 200
        say @@last_pain
        @@pain_counter += 1
      else
        @@last_pain = nil
      end
    elsif !got_hit.empty?
      @@last_pain = pain_words.sample
      say @@last_pain
    end
  end

  def pain_words
    [
      'OUCH!', 'OW!', 'That hurt!', 'You\ll pay for that!',
      'It\s just a flesh wound.', 'Is that the best you can do?'
    ]
  end



end
