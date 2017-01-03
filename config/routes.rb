require "resque_web"

Rails.application.routes.draw do
  root :to => 'sessions#index'

  # Accounts
  match '/login' => 'sessions#new', :as => :login, :via => :get
  match '/login' => 'sessions#create', :as => :login, :via => :post
  match '/logout' => 'sessions#destroy', :as => :logout, :via => :delete
  match '/users/:id/templates' => redirect('/users/%{id}/characters'), via: :get
  resources :users do
    resources :characters, only: :index
    resources :galleries, only: [:index, :show]
    resources :boards, only: :index
    collection do
      post :username
    end
    member do
      put :password
    end
  end
  resources :password_resets, only: [:new, :create, :show, :update]

  # Messages and notifications
  resources :messages, except: [:edit, :update, :destroy] do
    collection { post :mark }
  end

  # Characters
  resources :templates, except: :index
  resources :characters do
    member do
      post :icon
      get :replace
      post :do_replace
    end
    collection { get :facecasts }
  end

  # Images
  resources :icons, except: [:index, :new, :create] do
    member do
      post :avatar
      get :replace
      post :do_replace
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
    member do
      get :history
      get :stats
      post :warnings
    end
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
    collection { get :search }
  end
  resources :tags

  # Miscellaneous
  resources :reports, only: [:index, :show]
  resources :bugs, only: :create
  resources :favorites, only: [:index, :create, :destroy]
  match '/contribute' => 'contribute#index', as: :contribute, via: :get
  mount ResqueWeb::Engine => "/resque_web"
end
