class Sound < ApplicationRecord
  ACCEPTED_CONTENT_TYPES = %w[audio/wav audio/x-wav audio/wave audio/mpeg audio/mp3 audio/flac audio/x-flac].freeze

  belongs_to :user
  has_one_attached :audio

  validates :title, presence: true
  validates :audio, presence: true
  validate :audio_must_be_accepted_format

  private

  def audio_must_be_accepted_format
    return unless audio.attached?
    return if ACCEPTED_CONTENT_TYPES.include?(audio.content_type)

    errors.add(:audio, "must be a .wav, .mp3, or .flac file")
  end
end
