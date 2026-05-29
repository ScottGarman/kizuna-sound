class User < ApplicationRecord
  has_secure_password
  has_many :sounds, dependent: :destroy

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :email, presence: true, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :only_one_user, on: :create

  private

  def only_one_user
    errors.add(:base, "only one admin user is allowed") if User.exists?
  end
end
