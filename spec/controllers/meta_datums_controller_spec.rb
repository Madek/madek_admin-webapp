require 'spec_helper'

describe MetaDatumsController do
  let(:admin) { create :admin_user }

  describe '#index' do
    before { get :index, session: { user_id: admin.id } }

    it 'responds with HTTP 200 status code' do
      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    it 'renders index template' do
      expect(response).to render_template :index
    end

    it 'assigns @meta_datums correctly' do
      expect(assigns[:meta_datums]).not_to be_nil
    end

    context 'filtering by ID' do
      let(:meta_datum) { create :meta_datum_title }

      it 'assigns @meta_datums correctly' do
        get(
          :index,
          params: { search_term: meta_datum.id, search_by: :id },
          session: { user_id: admin.id }
        )

        expect(response).to be_successful
        expect(assigns[:meta_datums]).to eq [meta_datum]
      end
    end

    context 'filtering by string' do
      let(:meta_datum) { create :meta_datum_title, string: 'foo bar' }

      it 'assigns @meta_datums correctly' do
        get(
          :index,
          params: { search_term: 'o b', search_by: :string },
          session: { user_id: admin.id })

        expect(response).to be_successful
        expect(assigns[:meta_datums]).to include meta_datum
      end
    end
  end
end
