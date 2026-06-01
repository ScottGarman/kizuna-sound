class CreateLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :links do |t|
      t.references :setting, null: false, foreign_key: true
      t.string :title, null: false
      t.string :url, null: false
      # Stored now so drag-to-reorder can be added later without a migration.
      # Until then, links display in insertion order.
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
