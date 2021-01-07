Rails.application.routes.draw do
  resources :users, only: [:new, :create]
  resources :rooms, only: :show do
    resources :messages, only: [:create, :edit, :update, :destroy]
  end

  root to: "rooms#show"
end
