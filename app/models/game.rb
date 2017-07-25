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
    state :count_result
    state :game_over
    event :next do
      transitions from: :settings,to: :select_players
      transitions from: :select_players, to: :game, after => :set_pending_fouls
      transitions from: :game, to: :count_result
      transitions from: :count_result, to: :game_over
    end
  end

  def set_pending_fouls
    randomize
    players.each do |player|
      player.add_points('fouls', [player.user.pending_fouls, 3].min)
      player.add_points('pending_fouls', 0 - [player.user.pending_fouls, 3].min)
    end
  end

  def set_rating (value)
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
    players.last.delete unless players.count == 0
  end
end
