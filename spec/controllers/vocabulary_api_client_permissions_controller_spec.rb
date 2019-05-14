require 'spec_helper'

describe VocabularyApiClientPermissionsController do
  let(:admin_user) { create :admin_user }
  let(:vocabulary) { create :vocabulary }

  describe '#index' do
    let(:first_api_client_permission) do
      create(:vocabulary_api_client_permission, vocabulary: vocabulary)
    end
    let(:second_api_client_permission) do
      create(:vocabulary_api_client_permission, vocabulary: vocabulary)
    end
    before do
      get(
        :index,
        params: { vocabulary_id: vocabulary.id },
        session: { user_id: admin_user.id })
    end

    it 'responds with HTTP 200 status code' do
      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    it 'assigns @api_client_permissions correctly' do
      expect(assigns[:api_client_permissions]).to eq(
        [first_api_client_permission, second_api_client_permission])
    end
  end

  describe '#new' do
    let(:new_api_client) { create(:api_client) }

    it 'assigns locals correctly' do
      get(
        :new,
        params: { vocabulary_id: vocabulary.id },
        session: { user_id: admin_user.id })

      expect(assigns[:vocabulary]).to eq vocabulary
      expect(assigns[:permission]).to be_an_instance_of(
        Permissions::VocabularyApiClientPermission)
    end

    it "assigns api_client_id value of permission's instance from params" do
      get(:new,
          params: {
            vocabulary_id: vocabulary.id,
            api_client_id: new_api_client.id },
          session: { user_id: admin_user.id })

      expect(assigns[:permission].api_client_id).to eq new_api_client.id
    end

    it 'renders new template' do
      get(
        :new,
        params: { vocabulary_id: vocabulary.id },
        session: { user_id: admin_user.id })

      expect(response).to render_template(:new)
    end
  end

  describe '#create' do
    it 'creates a permission correctly' do
      expect do
        post(:create,
             params: {
               vocabulary_id: vocabulary.id,
               vocabulary_api_client_permission: {
                 api_client_id: create(:api_client).id
               }
             },
             session: { user_id: admin_user.id })
      end.to change { Permissions::VocabularyApiClientPermission.count }.by(1)
    end

    it 'reset session vocabulary_id key' do
      session[:vocabulary_id] = 123

      post(:create,
           params: {
             vocabulary_id: vocabulary.id,
             vocabulary_api_client_permission: {
               api_client_id: create(:api_client).id
             }
           },
           session: { user_id: admin_user.id })

      expect(session[:vocabulary_id]).to be_nil
    end

    it 'redirects to admin vocabulary api client permissions path' do
      post(:create,
           params: {
             vocabulary_id: vocabulary.id,
             vocabulary_api_client_permission: {
               api_client_id: create(:api_client).id
             }
           },
           session: { user_id: admin_user.id })

      expect(response).to redirect_to(
        vocabulary_vocabulary_api_client_permissions_url(vocabulary))
    end

    it 'sets a correct flash message' do
      post(:create,
           params: {
             vocabulary_id: vocabulary.id,
             vocabulary_api_client_permission: {
               api_client_id: create(:api_client).id
             }
           },
           session: { user_id: admin_user.id })

      expect(flash[:success]).to eq(
        'The Vocabulary Api Client Permission has been created.')
    end
  end

  describe '#edit' do
    let(:permission) do
      create(:vocabulary_api_client_permission, vocabulary: vocabulary)
    end
    let(:new_api_client) { create(:api_client) }

    it 'assigns locals correctly' do
      get(:edit,
          params: { vocabulary_id: vocabulary.id, id: permission.id },
          session: { user_id: admin_user.id })

      expect(assigns[:vocabulary]).to eq vocabulary
      expect(assigns[:permission]).to eq permission
    end

    it "assigns user_id value of permission's instance from params" do
      get(:edit,
          params: {
            vocabulary_id: vocabulary.id,
            id: permission.id,
            api_client_id: new_api_client.id },
          session: { user_id: admin_user.id })

      expect(assigns[:permission].api_client_id).to eq new_api_client.id
    end
  end

  describe '#update' do
    let(:permission) do
      create(:vocabulary_api_client_permission,
             vocabulary: vocabulary,
             use: false,
             view: true)
    end
    let(:new_api_client) { create(:api_client) }

    before do
      patch :update,
            params: {
              vocabulary_api_client_permission: {
                api_client_id: new_api_client.id,
                use: true,
                view: false
              },
              vocabulary_id: vocabulary.id,
              id: permission.id
            },
            session: { user_id: admin_user.id }
    end

    it 'updates the permission' do
      permission.reload

      expect(permission.api_client_id).to eq new_api_client.id
      expect(permission.use).to be true
      expect(permission.view).to be false
    end

    it 'redirects to vocabulary api client permissions path' do
      expect(response).to redirect_to(
        vocabulary_vocabulary_api_client_permissions_url(vocabulary))
      expect(flash[:success]).to eq(
        'The Vocabulary Api Client Permission has been updated.')
    end
  end

  describe '#destroy' do
    it 'deletes the permission' do
      permission = create(:vocabulary_api_client_permission,
                          vocabulary: vocabulary)

      expect do
        delete(:destroy,
               params: {
                 vocabulary_id: vocabulary.id,
                 id: permission.id
               },
               session: { user_id: admin_user.id })
      end.to change { Permissions::VocabularyApiClientPermission.count }.by(-1)
    end
  end
end
