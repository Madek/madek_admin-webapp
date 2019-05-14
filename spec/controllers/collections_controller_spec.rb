require 'spec_helper'

describe CollectionsController do
  let(:admin_user) { create :admin_user }

  describe '#index' do
    it 'responds with status code 200' do
      get :index, session: { user_id: admin_user.id }

      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end
  end

  describe '#show' do
    let!(:collection) { create :collection }

    it 'responds with status code 200' do
      get :show, params: { id: collection.id }, session: { user_id: admin_user.id }
      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    it 'renders the show template' do
      get :show, params: { id: collection.id }, session: { user_id: admin_user.id }
      expect(response).to render_template(:show)
    end

    it 'loads the proper models into variables' do
      get :show, params: { id: collection.id }, session: { user_id: admin_user.id }
      expect(assigns[:collection]).to eq collection
      expect(assigns[:user]).to eq collection.responsible_user
    end
  end

  describe '#media_entries' do
    let!(:collection) { create :collection }

    it 'responds with status code 200' do
      get(
        :media_entries,
        params: { id: collection.id },
        session: { user_id: admin_user.id })
      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    it 'renders the show template' do
      get(
        :media_entries,
        params: { id: collection.id },
        session: { user_id: admin_user.id })
      expect(response).to render_template(:media_entries)
    end

    it 'loads the proper models into variables' do
      get(
        :media_entries,
        params: { id: collection.id },
        session: { user_id: admin_user.id })
      expect(assigns[:collection]).to eq collection
      expect(assigns[:user]).to eq collection.responsible_user
      expect(assigns[:media_entries]).to eq collection.media_entries
    end
  end

  describe '#collections' do
    let!(:collection) { create :collection }

    it 'responds with status code 200' do
      get(
        :collections,
        params: { id: collection.id },
        session: { user_id: admin_user.id })
      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    it 'renders the show template' do
      get(
        :collections,
        params: { id: collection.id },
        session: { user_id: admin_user.id })
      expect(response).to render_template(:collections)
    end

    it 'loads the proper models into variables' do
      get(
        :collections,
        params: { id: collection.id },
        session: { user_id: admin_user.id })
      expect(assigns[:collection]).to eq collection
      expect(assigns[:user]).to eq collection.responsible_user
      expect(assigns[:collections]).to eq collection.collections
    end
  end
end
