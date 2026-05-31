class Tag < ApplicationRecord
  has_many :taggings, dependent: :destroy
  has_many :sounds, through: :taggings

  before_validation :normalize_name
  validates :name, presence: true, uniqueness: true

  # Lower-cased, trimmed, internal whitespace collapsed. Used both as the
  # before_validation normalizer and when matching a ?tag= filter param.
  def self.normalize(name)
    name.to_s.strip.downcase.squeeze(" ")
  end

  private

  def normalize_name
    self.name = self.class.normalize(name)
  end
end
