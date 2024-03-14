class List < ApplicationRecord

  has_many :list_items
  has_many :products, through: :backpack_items

end
