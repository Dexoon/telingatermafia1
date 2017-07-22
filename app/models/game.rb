class Game < ApplicationRecord
  has_one :Host
  has_many :players, -> { order(position: :asc) }

  def delete
    players.map { |player| player.delete  }
    destroy
  end

  def add_player(identity)
    players.create(user_id: identity) if players.find_by(user_id: identity).nil?
  end

  def delete_last
    players.last.delete unless players.count == 0
  end

  def player_list
    return 'Никого' if players.count.zero?
    list = ''
    players.order(:position).map { |player| list += player.position.to_s + ' ' + player.user.name + ' ' + player.user.surname + "\n" }
    list
  end

  def player_list_with_score
    return 'Никого' if players.count.zero?
    list = ''
    players.order(:position).map { |player| list += player.position.to_s + ' ' + player.score.to_s + ' ' + player.user.name + ' ' + player.user.surname + "\n" }
    list
  end

  include AASM
  aasm do
    state :select_players, initial: true
    state :count_result
    state :game_over
    event :start_game do
      transitions from: :select_players, to: :count_result
    end
    event :end_game do
      transitions from: :count_result, to: :game_over
    end
  end
end
