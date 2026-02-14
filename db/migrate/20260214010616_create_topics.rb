class CreateTopics < ActiveRecord::Migration[7.1]
  def change
    create_table :topics do |t|
      t.string :name
      t.text :content
      t.text :system_prompt

      t.timestamps
    end
  end
end
