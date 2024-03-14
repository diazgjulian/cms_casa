Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  resources :users
  get "/signup", to: "users#new"
  get "/login", to: "sessions#new"
  post "/sessions", to: "sessions#create"
  delete "/sessions", to: "sessions#destroy"

  resources :lists
  resources :products
  resources :kinds

  post '/lists/:id/add/:product_id', to: 'lists#add_product', as: :add_product_lists
  delete '/lists/:id/remove/:product_id', to: 'lists#remove_product', as: :remove_product_lists


  # Defines the root path route ("/")
  root "lists#index"
end
