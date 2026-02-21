class CreateCourts < ActiveRecord::Migration[7.1]
  def change
    create_table :courts do |t|
      t.string :name
      t.string :suburb
      t.string :surface
      t.boolean :lights

      t.timestamps
    end
  end
end
