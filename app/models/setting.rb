class Setting < ApplicationRecord
  # Site links shown on the feed, in insertion (position) order. Edited inline on
  # the settings form; blank rows are dropped and rows can be deleted.
  has_many :links, -> { order(:position, :id) }, dependent: :destroy
  accepts_nested_attributes_for :links, allow_destroy: true, reject_if: :all_blank

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
end
