class AddTagsEnabledToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :tags_enabled, :boolean, null: false, default: true
  end
end
