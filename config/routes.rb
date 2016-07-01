Rails.application.routes.draw do
  root :to => 'sessions#index'

  # Accounts
  match '/login' => 'sessions#create', :as => :login, :via => :post
  match '/logout' => 'sessions#destroy', :as => :logout, :via => :delete
  resources :users do
    resources :characters, only: :index
    resources :templates, only: :index
    resources :galleries, only: [:index, :show]
    collection do
      post :username
    end
    member do
      post :character
      put :password
    end
  end
  resources :password_resets, only: [:new, :create, :show, :update]

  # Messages and notifications
  resources :messages, except: :edit do
    collection { post :mark }
  end

  # Characters
  resources :templates
  resources :characters do
    member do
      post :icon
    end
    collection { get :facecasts }
  end

  # Images
  resources :icons, except: [:index, :new, :create] do
    member do
      post :avatar
    end
    collection do
      delete :delete_multiple
    end
  end
  resources :galleries do
    member do
      get :add
      post :icon
    end
  end

  # Forums
  resources :boards do collection { post :mark } end
  resources :board_sections, except: :index
  resources :posts do
    member { get :history }
    collection do
      post :mark
      get :search
      get :owed
      get :unread
      get :hidden
      post :unhide
    end
  end
  resources :replies, except: [:index, :new] do
    member { get :history }
  end

  # Miscellaneous
  resources :reports, only: [:index, :show]
  resources :bugs, only: :create
end
