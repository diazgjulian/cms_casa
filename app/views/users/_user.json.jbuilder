json.extract! user, :id, :created_at, :updated_at, :deleted_at, :datetime, :name, :email, :password_digest, :created_at, :updated_at
json.url user_url(user, format: :json)
