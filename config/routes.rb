require "resque_web"

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  apipie

  root :to => 'sessions#index'

  # Accounts
  match '/login' => 'sessions#new', :as => :login, :via => :get
  match '/login' => 'sessions#create', :via => :post
  match '/logout' => 'sessions#destroy', :as => :logout, :via => :delete
  match '/users/:id/templates' => redirect('/users/%{id}/characters'), via: :get
  resources :users do
    resources :characters, only: :index
    resources :galleries, only: [:index, :show]
    resources :boards, only: :index
    collection do
      get :search
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
  resources :templates, except: :index do
    collection { get :search}
  end
  resources :characters do
    resources :aliases, only: [:new, :create, :destroy]
    member do
      get :replace
      post :do_replace
      post :duplicate
    end
    collection do
      get :search
      get :facecasts
    end
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
    collection { get :search}
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
  resources :tags, except: [:new, :create]

  # API
  namespace :api do
    namespace :v1 do
      resources :boards, only: [:index, :show]
      resources :board_sections do # TODO other types
        collection { post :reorder }
      end
      resources :characters, only: [:index, :show, :update] do
        collection { post :reorder }
      end
      resources :galleries, only: :show
      resources :icons do
        collection { post :s3_delete }
      end
      resources :posts, only: :show do
        resources :replies, only: :index
        collection { post :reorder }
      end
      resources :tags, only: [:index, :show]
      resources :templates, only: :index
      resources :users, only: :index
    end
  end

  # Miscellaneous
  resources :reports, only: [:index, :show]
  resources :bugs, only: :create
  resources :favorites, only: [:index, :create, :destroy]
  match '/contribute' => 'contribute#index', as: :contribute, via: :get
  mount ResqueWeb::Engine => "/resque_web"
end
