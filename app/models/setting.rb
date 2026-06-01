class Setting < ApplicationRecord
  ACCEPTED_BANNER_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze

  # How the banner is treated for text readability on the feed:
  #   light - white scrim over the banner, dark text (good for light images)
  #   dark  - dark scrim over the banner, light text (good for dark images)
  #   none  - no scrim; text sits directly on the image
  BANNER_OVERLAYS = %w[light dark none].freeze

  # Site links shown on the feed, in insertion (position) order. Edited inline on
  # the settings form; blank rows are dropped and rows can be deleted.
  has_many :links, -> { order(:position, :id) }, dependent: :destroy
  accepts_nested_attributes_for :links, allow_destroy: true, reject_if: :all_blank

  # The banner image shown behind the title/about section of the feed header.
  has_one_attached :banner

  # Virtual flag set by the "Remove banner" checkbox on the settings form; the
  # controller purges the attachment when it is checked.
  attr_accessor :remove_banner

  validates :banner_overlay, inclusion: { in: BANNER_OVERLAYS }
  validate :banner_must_be_an_image

  # Global site settings are a singleton: there is only ever one row. Use
  # Setting.current everywhere to read it. It returns an unpersisted record when
  # no row exists yet, so reads never write to the database; saving (via the
  # settings form) inserts the single row.
  def self.current
    first || new
  end

  # The site title shown as the feed heading, falling back to a generic default
  # when the admin has not set one.
  def site_title
    title.presence || "Sounds"
  end

  private

  def banner_must_be_an_image
    return unless banner.attached?
    return if ACCEPTED_BANNER_TYPES.include?(banner.content_type)

    errors.add(:banner, "must be a JPEG, PNG, GIF, or WebP image")
  end
end
