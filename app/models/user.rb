class User < ApplicationRecord
  has_many :players
  scope :online, -> { where(online: true) }
  scope :available, -> (game) {where.not(id:game.players.map{|x| x.user_id})}
end
