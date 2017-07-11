class Game < ApplicationRecord
  has_one :Host
  has_many :players, -> { order(position: :asc) }
end
