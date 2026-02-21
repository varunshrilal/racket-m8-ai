class CreatePlayers < ActiveRecord::Migration[7.1]
  def change
    create_table :players do |t|
      t.string :name
      t.string :suburb
      t.decimal :utr
      t.string :level_label

      t.timestamps
    end
  end
end
