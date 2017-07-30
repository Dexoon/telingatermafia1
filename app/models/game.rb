class Game < ApplicationRecord
  has_one :Host
  has_many :players, -> { order(position: :asc) }

  before_create do
    self.day = (Time.now - 3 * 60 * 60).to_date unless day
  end

  include AASM
  aasm do
    state :settings, initial: true
    state :select_players
    state :game
    state :set_result
    state :set_score
    state :game_over
    event :next do
      transitions from: :settings, to: :select_players
      transitions from: :select_players, to: :game, after: :set_pending_fouls
      transitions from: :game, to: :set_result
      transitions from: :set_result, to: :set_score
      transitions from: :set_score, to: :game_over
    end
    event :back do
      transitions from: :select_players, to: :settings
      transitions from: :game, to: :select_players, after: :fous_to_pending
      transitions from: :set_result, to: :game
      transitions from: :set_score, to: :set_result
      transitions from: :game_over, to: :set_score
    end
  end

  def to_s(options = {})
    options.reverse_merge!(
      'players' => true,
      'day' => true,
      'day_format' => :short,
      'result' => false,
      'id' => true,
      'rating' => true,
      'order_players' => 'position'
    )
    str = ''
    str += day.to_s(options['day_format']) + "\n" if options['day']
    str += ' id игры: ' + id.to_s + "\n" if options['id']
    if options['rating']
      str += 'Игра '
      str += 'не ' unless rating
      str += 'рейтинговая' + "\n"
    end
    if options['result']
      case result
      when -1
        str += 'Победила мафия' + "\n"
      when 0
        str += 'Ничья' + "\n"
      when 1
        str += 'Победили мирные' + "\n"
      end
    end
    if options['players']
      case options['order_players']
      when 'score'
        players.sort_by { |player| - player.score }.each { |player| str += player.to_s(options) + "\n" }
      else
        players.order(options['order_players']).each { |player| str += player.to_s(options) + "\n" }
      end
    end
    str
  end

  def set_pending_fouls
    players.each do |player|
      player.add_points('fouls', [player.user.pending_fouls, 3].min)
      player.add_points('pending_fouls', 0 - [player.user.pending_fouls, 3].min)
    end
  end

  def fouls_to_pending
    players.each do |player|
      player.add_points('pending_fouls', player.fouls)
      player.update(fouls: 0)
    end
  end

  def set_result(value)
    update(result: value)
  end

  def set_rating(value)
    update(rating: value)
  end

  def change_rating
    set_rating(!rating)
  end

  def delete
    players.map(&:delete)
    destroy
  end

  def add_player(identity)
    players.create(user_id: identity) if players.find_by(user_id: identity).nil?
  end

  def randomize
    n = players.count - 1
    new_order = Array.new(n + 1, 0)
    base = (0..n).to_a
    for i in 0..n
      y = (rand * (n + 1 - i)).to_i
      new_order[i] = 1 + base[y]
      base.delete_at(y)
    end
    i = 0
    players.each do |player|
      player.insert_at(new_order[i])
      i += 1
    end
  end

  def delete_last
    players.last.delete unless players.count.zero?
  end
end
