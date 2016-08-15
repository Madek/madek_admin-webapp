require 'spec_helper'

describe MediaEntriesController do
  let(:admin_user) { create :admin_user }

  describe '#index' do
    it 'responds with HTTP 200 status code' do
      get :index, nil, user_id: admin_user.id

      expect(response).to be_success
      expect(response).to have_http_status(200)
    end

    it 'loads the first page of media entries into @media_entries' do
      get :index, nil, user_id: admin_user.id

      expect(response).to be_success
      expect(assigns(:media_entries)).to eq MediaEntry.first(16)
    end

    describe 'filtering' do
      context 'by uuid' do
        it 'returns a media entry' do
          media_entry = create :media_entry

          get :index, { search_term: media_entry.id }, user_id: admin_user.id

          expect(response).to be_success
          expect(response).to have_http_status(200)
          expect(assigns[:media_entries]).to eq [media_entry]
        end
      end

      context 'by title' do
        it 'returns a media entry' do
          media_entry = create :media_entry_with_title, title: 'TITLE'

          get :index, { search_term: 'TITLE' }, user_id: admin_user.id

          expect(assigns[:media_entries]).to eq [media_entry]
          expect(media_entry.title).to eq 'TITLE'
        end
      end

      context 'by is_published=false attribute' do
        it 'returns a media entry' do
          media_entry = create :media_entry, is_published: false

          get :index, { filter: { is_published: '0' } }, user_id: admin_user.id

          expect(assigns[:media_entries]).to eq [media_entry]
        end
      end

      context 'by is_published=true attribute' do
        it 'returns a media entry' do
          create :media_entry

          get :index, { filter: { is_published: '1' } }, user_id: admin_user.id

          expect(assigns[:media_entries].map(&:is_published).uniq).to eq [true]
        end
      end
    end
  end

  describe '#show' do
    let(:media_entry) { create :media_entry }
    before { get :show, { id: media_entry.id }, user_id: admin_user.id }

    it 'responds with 200 HTTP status code' do
      expect(response).to be_success
      expect(response).to have_http_status(200)
    end

    it 'assigns @media_entry correctly' do
      expect(assigns[:media_entry]).to eq media_entry
    end
  end
end
