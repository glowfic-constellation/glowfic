Rails.application.routes.draw do
  root :to => 'sessions#index'
  match '/login' => 'sessions#create', :as => :login, :via => :post
  match '/logout' => 'sessions#destroy', :as => :logout, :via => :delete

  resources :templates
  resources :boards do collection { post :mark } end
  resources :messages, except: :edit do
    collection { post :mark }
  end
  resources :replies, except: [:index, :new] do
    member { get :history }
  end
  resources :posts do
    member { get :history }
    collection do
      post :mark
      get :search
      get :owed
      get :unread
    end
  end
  resources :characters do
    member do
      post :icon
    end
    collection { get :facecasts }
  end
  resources :icons, except: [:index, :new, :create] do
    member do
      post :avatar
    end
    collection do
      delete :delete_multiple
    end
  end
  resources :users do
    resources :characters, only: :index
    resources :templates, only: :index
    resources :galleries, only: :index
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
    end
  end
end
