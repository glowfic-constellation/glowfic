# frozen_string_literal: true
require 'resque/server'

Rails.application.routes.draw do
  resources :oauth_clients
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  apipie

  root to: 'sessions#index'

  # Accounts
  get '/login' => 'sessions#new', as: :login
  post '/login' => 'sessions#create'
  delete '/logout' => 'sessions#destroy', as: :logout
  patch '/confirm_tos' => 'sessions#confirm_tos', as: :confirm_tos
  get '/users/:id/templates' => redirect('/users/%{id}/characters')
  resources :users, except: :destroy do
    resources :characters, only: :index
    resources :galleries, only: [:index, :show]
    resources :boards, only: :index
    collection do
      get :search
    end
    member do
      put :password
      put :upgrade
      get :output
      get :profile_edit
    end
  end
  resources :password_resets, only: [:new, :create, :show, :update]

  # Messages and notifications
  resources :messages, except: [:edit, :update, :destroy] do
    collection { post :mark }
  end
  resources :notifications, only: [:index] do
    collection { post :mark }
  end

  # Characters
  resources :templates, except: :index do
    collection { get :search }
  end
  resources :characters do
    resources :aliases, only: [:new, :create, :edit, :update, :destroy]
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
    collection { get :search }
  end

  # Forums
  resources :boards, as: :continuities do
    collection do
      post :mark
      get :search
    end
  end
  resources :board_sections, except: :index
  resources :posts do
    member do
      get :history
      get :delete_history
      get :stats
      post :warnings
      get :split
      post :do_split
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
    member do
      get :history
      post :restore
    end
    collection { get :search }
  end
  resources :drafts, only: [:create, :destroy]
  resources :bookmarks, only: [:create, :destroy] do
    collection { get :search }
  end
  resources :tags, except: [:new, :create]

  # Indexes
  resources :indexes
  resources :index_sections, except: [:index]
  resources :index_posts, only: [:new, :create, :edit, :update, :destroy]

  # Blocks
  resources :blocks, except: [:show]

  # OAuth2
  namespace :oauth do
    get :test_request
    post :revoke
    post :token
    get :access_token
    post :authorize
    get :authorize
    match '',               :to => 'oauth#index',         :via => :get, :as => :oauth
  end
  # API
  namespace :api do
    namespace :v1 do
      resources :boards, only: [:index, :show] do
        member { get :posts }
      end
      resources :subcontinuities, only: [:show] do
        collection { post :reorder }
      end
      resources :characters, only: [:index, :show, :update] do
        collection { post :reorder }
      end
      resources :galleries, only: :show
      resources :icons, only: [] do
        collection { post :s3_delete }
      end
      resources :index_posts, only: [] do
        collection { post :reorder }
      end
      resources :index_sections, only: [] do
        collection { post :reorder }
      end
      resources :replies, only: [] do
        member { get :bookmark }
      end
      resources :posts, only: [:index, :show, :update] do
        resources :replies, only: :index
        collection { post :reorder }
      end
      resources :bookmarks, only: [:create, :update, :destroy]
      resources :tags, only: [:index, :show]
      resources :templates, only: :index
      resources :users, only: :index do
        member do
          get :posts
          get :bookmarks
        end
      end

      post '/login' => 'sessions#create', as: :login
    end
  end

  # Legalese
  get '/tos' => 'about#tos', as: :tos
  get '/privacy' => 'about#privacy', as: :privacy
  get '/contact' => 'about#contact', as: :contact
  get '/dmca' => 'about#dmca', as: :dmca

  # Miscellaneous
  resources :reports, only: [:index, :show]
  resources :news
  resources :bugs, only: :create
  resources :favorites, only: [:index, :create, :destroy]
  get '/contribute' => 'contribute#index', as: :contribute
  mount Resque::Server.new, at: "/resque_web"

  # Admin Panel
  scope module: :admin, path: :admin do
    root to: 'admin#index', as: :admin

    resources :posts, only: [] do
      collection do
        get :regenerate_flat
        post :do_regenerate
      end
    end
    resources :characters, only: [] do
      collection do
        get :relocate
        post :do_relocate
      end
    end
  end
end
