class CreateLists < ActiveRecord::Migration[7.0]
  def change
    create_table :lists do |t|
      t.string :name
      t.timestamps
    end
    add_column :lists, :product_ids, :bigint, array: true
  end
end
