class Product < ApplicationRecord

  has_many :list_items
  has_many :lists, through: :backpack_items

end
