Rails.application.routes.draw do
  get 'chats/show'
  get 'topics/index'
  get 'topics/show'
  devise_for :users
  root to: "pages#home"

  resources :topics, only: [:index, :show] do
    resources :chats, only: [:create]
  end

  resources :chats, only: [:show] do
    resources :messages, only: [:create]
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
