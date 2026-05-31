class Tagging < ApplicationRecord
  belongs_to :sound
  belongs_to :tag
end
