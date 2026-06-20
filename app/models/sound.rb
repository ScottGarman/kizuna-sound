class Sound < ApplicationRecord
  ACCEPTED_CONTENT_TYPES = %w[audio/wav audio/x-wav audio/wave audio/mpeg audio/mp3 audio/flac audio/x-flac].freeze

  extend FriendlyId
  # Show pages live at /sounds/:slug (e.g. /sounds/midnight-rain) so the
  # database id is never exposed. History keeps old slugs resolving after a
  # title is edited, so previously shared links never break.
  friendly_id :title, use: [ :slugged, :history ]

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

  # Stale peaks are cleared the moment new audio is attached (before the row is
  # written), then regenerated after commit once the new blob is stored. Editing
  # anything other than the audio leaves the cached waveform untouched.
  before_save :reset_waveform_if_audio_changed
  after_commit :generate_waveform, on: %i[create update], if: :waveform_missing?

  # Refresh the slug when the title changes (and on create, when it's blank).
  # The previous slug is preserved by :history so old links keep working.
  def should_generate_new_friendly_id?
    title_changed? || super
  end

  private

  # Active Storage records a pending attachment under "audio" until the save
  # persists it, so this fires for both the initial upload and a replacement.
  def reset_waveform_if_audio_changed
    return unless attachment_changes.key?("audio")

    self.waveform_peaks = nil
    self.duration = nil
  end

  def waveform_missing?
    audio.attached? && waveform_peaks.blank?
  end

  def generate_waveform
    GenerateWaveformJob.perform_later(id)
  end

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
