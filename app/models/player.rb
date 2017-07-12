class Player < ApplicationRecord
  belongs_to :user
  belongs_to :game
  acts_as_list scope: :game
end
