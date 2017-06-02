Rails.application.routes.draw do

  scope '/admin' do
    get :status, controller: :application, action: :status

    concern :orderable do
      patch :move_up, on: :member
      patch :move_down, on: :member
    end

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
        get :form_merge_to
        post :merge_to
        get :form_add_user
        patch :add_user
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
      end
    end
    resources :media_entries, only: [:index, :show]
    resources :media_files, only: [:index, :show] do
      post :reencode, on: :member
      get :batch_reencoding, on: :collection
      post :batch_reencode, on: :collection
    end
    resources :previews, only: [:show, :destroy] do
      get :raw_file
    end
    resources :zencoder_jobs, only: :show
    resources :vocabularies, concerns: :orderable do
      resources :vocabulary_user_permissions, path: 'user_permissions'
      resources :vocabulary_group_permissions, path: 'group_permissions'
      resources :vocabulary_api_client_permissions, path: 'api_client_permissions'
    end
    resources :meta_keys, concerns: :orderable do
      get :move, action: :move_form
      post :move, action: :move
    end
    resources :contexts do
      patch :add_meta_key, on: :member
    end
    resources :context_keys, only: [:edit, :update, :destroy], concerns: :orderable do
      patch :move_to_top, on: :member
      patch :move_to_bottom, on: :member
    end
    resources :meta_datums, only: :index
    resources :io_mappings
    resources :io_interfaces, except: [:edit, :update]
    resources :app_settings, only: [:index, :edit, :update]
    resources :usage_terms, except: :edit
    resources :keywords, concerns: :orderable do
      get :usage, on: :member
      get :form_merge_to, on: :member
      post :merge_to, on: :member
    end

    resources :people

    root to: 'dashboard#index'
    post 'dashboard/refresh', to: 'dashboard#refresh'

    resource :assistant, only: [:show] do
      get 'sql_reports'
    end

  end

end
