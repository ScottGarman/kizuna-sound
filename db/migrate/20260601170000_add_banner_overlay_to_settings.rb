class AddBannerOverlayToSettings < ActiveRecord::Migration[8.1]
  def change
    # "light" preserves the original behaviour (white scrim, dark text).
    add_column :settings, :banner_overlay, :string, null: false, default: "light"
  end
end
