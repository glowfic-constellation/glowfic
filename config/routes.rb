Rails.application.routes.draw do
  root :to => 'sessions#index'
  match '/login' => 'sessions#create', :as => :login, :via => :post
  match '/logout' => 'sessions#destroy', :as => :logout, :via => :delete

  resources :templates
  resources :boards
  resources :messages, except: :edit do
    collection { post :mark }
  end
  resources :replies do
    member { get :history }
    collection do
      post :preview
    end
  end
  resources :posts do
    member { get :history }
    collection do
      post :preview
      get :search
      get :owed
    end
  end
  resources :characters do
    member do
      post :icon
    end
    collection { get :facecasts }
  end
  resources :icons do
    member do
      post :avatar
    end
  end
  resources :users do
    resources :characters, only: :index
    collection do
      post :username
    end
    member do
      post :character
      put :password
    end
  end
  resources :galleries do
    member do
      get :add
      post :icon
      delete :remove
    end
  end
end
