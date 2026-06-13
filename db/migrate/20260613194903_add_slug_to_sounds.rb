class AddSlugToSounds < ActiveRecord::Migration[8.1]
  def change
    add_column :sounds, :slug, :string
    add_index :sounds, :slug, unique: true
  end
end
