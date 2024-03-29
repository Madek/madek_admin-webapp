require 'spec_helper'

describe DashboardController do
  let(:admin_user) { create :admin_user }

  context 'authorization' do
    context "when user isn't authorized" do
      it 'renders 401 message' do
        get :index

        expect(response).to have_http_status(:unauthorized)
        expect(response).to render_template('errors/401')
      end
    end

    context 'when user is authorized but not admin' do
      it 'renders 403 message' do
        user = FactoryBot.create :user

        get :index, session: { user_id: user.id }

        expect(response).to have_http_status(:forbidden)
        expect(response).to render_template('errors/403')
      end
    end

    context 'when user is authorized and is an admin' do
      it 'renders dashboard template' do
        user = FactoryBot.create :admin_user

        get :index, session: { user_id: user.id }

        expect(response).to be_successful
        expect(response.body).to render_template 'dashboard/index'
      end
    end
  end

  describe '#index' do
    before { get :index, session: { user_id: admin_user.id } }

    it 'responds with status code 200' do
      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    it 'renders template' do
      expect(response).to render_template 'dashboard/index'
    end

    it 'assigns @data with array' do
      expect(assigns[:data][:resources]).to be_an Array
      expect(assigns[:data][:resources]).not_to be_empty
    end
  end
end
