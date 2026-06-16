class AddPlayCountToSounds < ActiveRecord::Migration[8.1]
  def change
    add_column :sounds, :play_count, :integer, default: 0, null: false
  end
end
