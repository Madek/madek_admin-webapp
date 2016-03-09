require 'spec_helper'

describe DashboardController do

  context 'authorization' do
    context "when user isn't authorized" do
      it 'renders 401 message' do
        get :index

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to eq 'Error 401 - Please log in!'
      end
    end

    context 'when user is authorized but not admin' do
      it 'renders 403 message' do
        user = FactoryGirl.create :user

        get :index, nil, user_id: user.id

        expect(response).to have_http_status(:forbidden)
        expect(response.body).to eq 'Error 403 - Admin access denied!'
      end
    end

    context 'when user is authorized and is an admin' do
      it 'renders dashboard template' do
        user = FactoryGirl.create :admin_user

        get :index, nil, user_id: user.id

        expect(response).to be_success
        expect(response.body).to render_template 'dashboard/index'
      end
    end
  end
end
