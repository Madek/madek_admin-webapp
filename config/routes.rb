Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  scope '/admin' do
    # drop-in replacement for auth module (not for production)
    if Rails.env.development? or Rails.env.test?
      get '/sign-in', to: 'test_auth#show', as: 'test_login'
      post '/sign-in', to: 'test_auth#sign_in', as: 'test_sign_in'
      post '/sign-out', to: 'test_auth#sign_out', as: 'test_sign_out'
    end

    get :status, controller: :application, action: :status

    concern :orderable do
      patch :move_to_top, on: :member
      patch :move_up, on: :member
      patch :move_down, on: :member
      patch :move_to_bottom, on: :member
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
    resources :context_keys, only: [:edit, :update, :destroy], concerns: :orderable
    resources :meta_datums, only: :index
    resources :io_mappings
    resources :io_interfaces, except: [:edit, :update]
    resources :app_settings, only: [:index, :edit, :update]
    resources :usage_terms, except: :edit
    resources :keywords, except: :show, concerns: :orderable do
      get :usage, on: :member
      get :form_merge_to, on: :member
      post :merge_to, on: :member
    end
    resources :sections, only: [:index, :edit, :update, :new, :create, :destroy]

    resources :people do
      post :merge_to, on: :member
    end

    resources :roles
    resources :delegations do
      member do
        get :form_add_group
        patch :add_group
        get :form_add_user
        patch :add_user
      end

      resources :users, only: [] do
        delete :remove_from_delegation
      end

      resources :groups, only: [] do
        delete :remove_from_delegation
      end
    end
    resources :static_pages, only: [:edit, :update, :create, :new, :destroy]

    root to: 'dashboard#index'
    post 'dashboard/refresh', to: 'dashboard#refresh'

    resource :assistant, only: [:show] do
      get 'sql_reports'

      get 'batch_translate'
      post 'batch_translate', action:'batch_translate_update'

      get 'csv_import_index'
      get 'csv_import_roles'
      post 'csv_import_roles_update'
    end

    get 'smtp_settings', to: 'smtp_settings#show', as: 'smtp_settings'
    get 'smtp_settings/edit', to: 'smtp_settings#edit', as: 'edit_smtp_settings'
    patch 'smtp_settings/update', to: 'smtp_settings#update', as: 'update_smtp_settings'

    resources :notification_templates, only: [:index, :show, :edit, :update]

  end

end
