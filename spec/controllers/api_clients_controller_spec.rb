require 'spec_helper'

describe ApiClientsController do
  let(:admin_user) { create :admin_user }

  describe '#index' do
    it 'responds with HTTP 200 status code' do
      get :index, session: { user_id: admin_user.id }

      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    it 'loads the first page of api_clients into api_clients' do
      get :index, session: { user_id: admin_user.id }

      expect(response).to be_successful
      expect(assigns(:api_clients)).to eq ApiClient.first(16)
    end
  end

  describe '#show' do
    let(:api_client) { create :api_client }

    it 'responds with HTTP 200 status code' do
      get :show, params: { id: api_client.id }, session: { user_id: admin_user.id }

      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    it 'renders the show template' do
      get :show, params: { id: api_client.id }, session: { user_id: admin_user.id }

      expect(response).to render_template(:show)
    end

    it 'loads the proper api_client into api_client' do
      get :show, params: { id: api_client.id }, session: { user_id: admin_user.id }

      expect(assigns[:api_client]).to eq api_client
    end
  end

  describe '#new' do
    let(:user) { create :user }
    let(:new_api_client_params) do
      {
        login: 'new_login',
        description: Faker::Lorem.words(number: 10).join(' '),
        user_id: user.id
      }
    end

    context 'when attributes in params are available' do
      it 'assigns @api_client correctly' do
        get(
          :new,
          params: { new_api_client: new_api_client_params },
          session: { user_id: admin_user.id }
        )

        expect(assigns[:api_client].login).to eq new_api_client_params[:login]
        expect(assigns[:api_client].description).to eq(
          new_api_client_params[:description])
        expect(assigns[:api_client].user).to eq user
      end
    end
  end

  describe '#edit' do
    let(:api_client) { create :api_client }

    it 'responds with HTTP 200 status code' do
      get :edit, params: { id: api_client.id }, session: { user_id: admin_user.id }

      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    it 'render the edit template and assigns the api_client to api_client' do
      get :edit, params: { id: api_client.id }, session: { user_id: admin_user.id }

      expect(response).to render_template(:edit)
      expect(assigns[:api_client]).to eq api_client
    end
  end

  describe '#update' do
    let(:api_client) { create :api_client }

    it 'redirects to admin api_client show page' do
      patch(
        :update,
        params: {
          id: api_client.id,
          api_client: { description: 'test description' } },
        session: { user_id: admin_user.id }
      )

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(api_client_path(api_client))
    end

    it 'updates the api_client' do
      patch(
        :update,
        params: {
          id: api_client.id,
          api_client: { description: 'test description' } },
        session: { user_id: admin_user.id }
      )

      expect(flash[:success]).to eq flash_message(:update, :success)
      expect(api_client.reload.description).to eq 'test description'
    end

    it 'updates permission_descriptions localized field' do
      patch(
        :update,
        params: {
          id: api_client.id,
          api_client: {
            permission_descriptions: {
              de: 'Beschreibung DE',
              en: 'Description EN'
            }
          }
        },
        session: { user_id: admin_user.id }
      )

      expect(response).to have_http_status(302)
      api_client.reload
      expect(api_client.permission_description(:de)).to eq 'Beschreibung DE'
      expect(api_client.permission_description(:en)).to eq 'Description EN'
    end

    context 'when params include change_user param' do
      let(:user) { create :user }
      let(:api_client_params) do
        {
          id: api_client.id,
          login: Faker::Lorem.words(number: 2).join('_').slice(0, 20),
          description: Faker::Lorem.words(number: 10).join(' '),
          user_id: user.id
        }
      end

      it 'redirects to users listing with proper url params' do
        patch(
          :update,
          params: {
            id: api_client.id,
            api_client: api_client_params,
            change_user: '' },
          session: { user_id: admin_user.id }
        )

        expect(response).to have_http_status(302)
        expect(response).to redirect_to(
          users_path(edited_api_client: api_client_params)
        )
      end
    end
  end

  describe '#create' do
    let(:user) { create :user }
    let(:api_client_params) do
      {
        login: Faker::Lorem.words(number: 2).join('_').slice(0, 20),
        description: Faker::Lorem.words(number: 10).join(' '),
        user_id: user.id
      }
    end

    it 'redirects to admin api_clients path after successful create' do
      post(
        :create,
        params: { api_client: api_client_params },
        session: { user_id: admin_user.id })

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(api_clients_path)
      expect(flash[:success]).to eq flash_message(:create, :success)
    end

    it 'creates an api_client' do
      expect do
        post(
          :create,
          params: { api_client: api_client_params },
          session: { user_id: admin_user.id })
      end.to change { ApiClient.count }.by(1)
    end

    it 'creates an api_client with permission_descriptions' do
      api_client_params[:permission_descriptions] = {
        de: 'Beschreibung DE',
        en: 'Description EN'
      }

      post(
        :create,
        params: { api_client: api_client_params },
        session: { user_id: admin_user.id }
      )

      expect(response).to have_http_status(302)
      created_client = ApiClient.find_by(login: api_client_params[:login])
      expect(created_client.permission_description(:de)).to eq 'Beschreibung DE'
      expect(created_client.permission_description(:en)).to eq 'Description EN'
    end

    context 'when user is missing' do
      it 'redirects to users listing with proper url params' do
        api_client_params[:user_id] = nil
        post(
          :create,
          params: { api_client: api_client_params },
          session: { user_id: admin_user.id })

        expect(response).to have_http_status(302)
        expect(response).to redirect_to(
          users_path(new_api_client: api_client_params)
        )
      end
    end
  end

  describe '#destroy' do
    let!(:api_client) { create :api_client }

    it 'redirects to admin api_clients path after succesful destroy' do
      delete(
        :destroy,
        params: { id: api_client.id },
        session: { user_id: admin_user.id })

      expect(response).to redirect_to(api_clients_path)
      expect(flash[:success]).to eq flash_message(:destroy, :success)
    end

    it 'destroys the api_client' do
      expect do
        delete(
          :destroy,
          params: { id: api_client.id },
          session: { user_id: admin_user.id })
      end.to change { ApiClient.count }.by(-1)
    end
  end

  def flash_message(action, type)
    I18n.t type, scope: "flash.actions.#{action}", resource_name: 'Api client'
  end
end
