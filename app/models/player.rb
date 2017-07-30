class Player < ApplicationRecord
  belongs_to :user
  belongs_to :game
  acts_as_list scope: :game

  # validate :validate_user_id

  #  def validate_user_id
  #    unless self.game.players.find_by(user_id: self.user_id).nil?
  #      errors.add(:company, 'User already plays')
  #    end
  #  end
  def to_s(options = {})
    options.reverse_merge!(
      'show_zero_score' => true,
      'position' => true,
      'position_roman' => false,
      'fouls' => false,
      'score' => false,
      'nest' => true
    )
    fouls_char = '|'
    str = ''
    if options['score']
      str += if options['show_zero_score'] || !score.zero?
               (score.to_circled + ' ').nest
             else
               '  '.nest
             end
    end
    if options['position']
      str += if options['position_roman']
               position.to_roman + ' '
             else
               position.to_s + ' '
             end
    end
    str += user.to_s(options)
    fouls.times { str += fouls_char } if options['fouls']
    str
  end

  def self.to_str(options = {})
    return 'Никого' if count.zero?
    list = ''
    all.each do |player|
      list += player.to_s(options) + "\n"
    end
    list
  end

  def add_points(category = 'score', value)
    case category
    when 'fouls'
      if value < 0
        update(fouls: [0, fouls + value].max)
      else
        update(fouls: [4, fouls + value].min)
      end
    when 'score'
      update(score: score + value)
    when 'pending_fouls'
      user.add_points('pending_fouls', value)
    end
  end
end
