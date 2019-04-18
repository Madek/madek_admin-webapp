require 'spec_helper'

describe MediaEntriesController do
  let(:admin_user) { create :admin_user }

  describe '#index' do
    it 'responds with HTTP 200 status code' do
      get :index, session: { user_id: admin_user.id }

      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    it 'loads the first page of media entries into @media_entries' do
      get :index, session: { user_id: admin_user.id }

      expect(response).to be_successful
      expect(assigns(:media_entries)).to eq MediaEntry.first(16)
    end

    describe 'filtering' do
      context 'by uuid' do
        it 'returns a media entry' do
          media_entry = create :media_entry

          get(
            :index,
            params: { search_term: media_entry.id },
            session: { user_id: admin_user.id })

          expect(response).to be_successful
          expect(response).to have_http_status(200)
          expect(assigns[:media_entries]).to eq [media_entry]
        end
      end

      context 'by title' do
        it 'returns a media entry' do
          media_entry = create :media_entry_with_title, title: 'TITLE'

          get(
            :index,
            params: { search_term: 'TITLE' },
            session: { user_id: admin_user.id })

          expect(assigns[:media_entries]).to eq [media_entry]
          expect(media_entry.title).to eq 'TITLE'
        end
      end

      context 'by is_published=false attribute' do
        it 'returns a media entry' do
          media_entry = create :media_entry, is_published: false

          get(
            :index,
            params: { filter: { is_published: '0' } },
            session: { user_id: admin_user.id })

          expect(assigns[:media_entries]).to eq [media_entry]
        end
      end

      context 'by is_published=true attribute' do
        it 'returns a media entry' do
          create :media_entry

          get(
            :index,
            params: { filter: { is_published: '1' } },
            session: { user_id: admin_user.id })

          expect(assigns[:media_entries].map(&:is_published).uniq).to eq [true]
        end
      end
    end
  end

  describe '#show' do
    let(:media_entry) { create :media_entry }
    before do
      get(
        :show,
        params: { id: media_entry.id },
        session: { user_id: admin_user.id })
    end

    it 'responds with 200 HTTP status code' do
      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    it 'assigns @media_entry correctly' do
      expect(assigns[:media_entry]).to eq media_entry
    end
  end
end
