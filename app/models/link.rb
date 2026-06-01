class Link < ApplicationRecord
  # A single web link shown on the feed (e.g. "Bandcamp" -> https://...).
  # Belongs to the singleton Setting; managed via nested attributes on the
  # settings form.
  belongs_to :setting

  validates :title, presence: true
  validates :url, presence: true
  validate :url_must_be_http

  # Assign a position when the link is created so new links append to the bottom.
  # We run this on :create only (not on every save) so editing a link's title or
  # URL never silently moves it. Drag-to-reorder can be layered on later by
  # rewriting these positions; until then they simply reflect insertion order.
  before_validation :assign_position, on: :create

  private

  def assign_position
    # Only auto-assign when no explicit position was set (position defaults to 0
    # in the DB, so 0 means "unset"). maximum(:position) reads the siblings
    # already saved in this transaction, so several links added in one form
    # submission each get the next number up.
    self.position = (setting&.links&.maximum(:position) || 0) + 1 if position.to_i.zero?
  end

  def url_must_be_http
    return if url.blank? # presence validation already reports a blank URL

    # Parse the URL and require it to be an HTTP(S) URL with a host. URI::HTTPS
    # is a subclass of URI::HTTP, so this single check accepts both http:// and
    # https://. Crucially it rejects schemes like "javascript:" and "data:",
    # which matters because these URLs are rendered as clickable href targets on
    # a public page and would otherwise be an XSS vector.
    uri = URI.parse(url)
    return if uri.is_a?(URI::HTTP) && uri.host.present?

    errors.add(:url, "must be a valid http:// or https:// URL")
  rescue URI::InvalidURIError
    # URI.parse raises on malformed input (e.g. "http://[bad"); treat as invalid.
    errors.add(:url, "must be a valid http:// or https:// URL")
  end
end
