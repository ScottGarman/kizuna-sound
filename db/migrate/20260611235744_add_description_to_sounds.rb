class AddDescriptionToSounds < ActiveRecord::Migration[8.1]
  def change
    add_column :sounds, :description, :text
  end
end
