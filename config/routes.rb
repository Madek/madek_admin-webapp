Rails.application.routes.draw do

  get :status, controller: :application, action: :status

  resources :api_clients
  resources :users do
    member do
      post :switch_to
      patch :reset_usage_terms
      patch :grant_admin_role
      delete :remove_admin_role
    end
    collection do
      get :new_with_person
    end
  end
  resources :groups do
    member do
      get 'form_add_user'
      post 'add_user'
      get 'form_merge_to'
      post 'merge_to'
    end
    resources :users, only: '' do
      delete :remove_user_from_group
    end
  end
  resources :api_clients, only: :index
  resources :collections, only: [:index, :show] do
    member do
      get :media_entries
      get :collections
      get :filter_sets
    end
  end
  resources :media_entries, only: [:index, :show]
  resources :media_files, only: :show
  resources :previews, only: [:show, :destroy] do
    get :raw_file
  end
  resources :zencoder_jobs, only: :show
  resources :filter_sets, only: [:index, :show]
  resources :vocabularies do
    resources :keywords
    resources :vocabulary_user_permissions, path: 'user_permissions'
    resources :vocabulary_group_permissions, path: 'group_permissions'
    resources :vocabulary_api_client_permissions, path: 'api_client_permissions'
  end
  resources :meta_keys
  resources :meta_datums, only: :index
  resources :io_mappings
  resources :io_interfaces, except: [:edit, :update]
  resources :app_settings, only: [:index, :edit, :update]

  resources :people

  root to: 'dashboard#index'

end
