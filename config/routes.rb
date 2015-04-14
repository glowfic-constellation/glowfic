Rails.application.routes.draw do
  root :to => 'sessions#index'
  match '/login' => 'sessions#create', :as => :login, :via => :post
  match '/logout' => 'sessions#destroy', :as => :logout, :via => :delete

  resources :users
  resources :icons
  resources :templates
  resources :galleries do
    member do
      get :add
      post :icon
    end
  end
  resources :characters
end
