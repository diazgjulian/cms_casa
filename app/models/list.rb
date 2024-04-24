class List < ApplicationRecord

  has_many :list_items
  has_many :products, through: :list_items

  def kind_name
    Kind.find(self.kind).name
  end

end
