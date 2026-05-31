class Sound < ApplicationRecord
  ACCEPTED_CONTENT_TYPES = %w[audio/wav audio/x-wav audio/wave audio/mpeg audio/mp3 audio/flac audio/x-flac].freeze

  belongs_to :user
  has_one_attached :audio
  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings

  validates :title, presence: true
  validates :audio, presence: true
  validate :audio_must_be_accepted_format

  # Comma-separated tag names typed into the "add new tags" form field. These
  # are created (or reused) and attached after the sound is saved, alongside
  # any existing tags selected via tag_ids.
  attr_writer :new_tag_names

  after_save :attach_new_tags

  private

  def attach_new_tags
    return if @new_tag_names.blank?

    names = @new_tag_names.split(",").map { |name| Tag.normalize(name) }.reject(&:blank?).uniq
    names.each do |name|
      tag = Tag.find_or_create_by(name: name)
      tags << tag unless tags.include?(tag)
    end
    @new_tag_names = nil
  end

  def audio_must_be_accepted_format
    return unless audio.attached?
    return if ACCEPTED_CONTENT_TYPES.include?(audio.content_type)

    errors.add(:audio, "must be a .wav, .mp3, or .flac file")
  end
end
