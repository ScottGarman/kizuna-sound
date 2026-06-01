class AddTitleToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :title, :string
  end
end
