Rails.application.routes.draw do
  root :to => 'sessions#index'
  match '/login' => 'sessions#create', :as => :login, :via => :post
  match '/logout' => 'sessions#destroy', :as => :logout, :via => :delete
end
