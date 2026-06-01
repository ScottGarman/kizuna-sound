class Setting < ApplicationRecord
  # Global site settings are a singleton: there is only ever one row. Use
  # Setting.current everywhere to read or update it; it creates the row lazily
  # the first time it is needed.
  def self.current
    first || create!
  end
end
