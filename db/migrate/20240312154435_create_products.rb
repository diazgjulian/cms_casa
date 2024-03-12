class CreateProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :products do |t|
      t.string :name
      t.string :token
      t.belongs_to :list, null: false, foreign_key: true

      t.timestamps
    end
  end
end
