class User < ApplicationRecord
  has_many :players
  scope :online, -> { where(online: true) }
  scope :available, ->(game) { where.not(id: game.players.map(&:user_id)) }
  def to_s(options = {})
    options.reverse_merge!(
      'name' => true,
      'surname' => true,
      'pending_fouls' => false
    )
    pending_fouls_char = '⦶' #
    str = ''
    str += name + ' ' if options['name']
    str += surname + ' ' if options['surname']
    pending_fouls.times { str += pending_fouls_char } if options['pending_fouls']
    str
  end

  def add_points(category = 'pending_fouls', value)
    case category
    when 'pending_fouls'
      update(pending_fouls: [0, pending_fouls + value].max)
    end
  end
end
