class CreateSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :settings do |t|
      # Individual setting columns are added in their own migrations as each
      # setting is implemented (title, about, tags toggle, etc.). This table is
      # a singleton — there is only ever one row of global site settings.

      t.timestamps
    end
  end
end
