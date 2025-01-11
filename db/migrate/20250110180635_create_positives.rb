class CreatePositives < ActiveRecord::Migration[6.0]
  def change
    create_table :positives do |t|
      t.string :word
      t.integer :count
      t.string :place
      t.date :datetime

      t.timestamps
    end
  end
end
