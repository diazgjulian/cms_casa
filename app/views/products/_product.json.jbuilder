json.extract! product, :id, :name, :token, :list_id, :created_at, :updated_at
json.url product_url(product, format: :json)
