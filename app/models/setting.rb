class Setting < ApplicationRecord
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
