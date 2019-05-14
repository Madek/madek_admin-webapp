require 'spec_helper'

describe UsageTermsController do
  let!(:admin_user) { create :admin_user }

  describe '#index' do
    before { get :index, session: { user_id: admin_user.id } }

    it 'responds with HTTP 200 status code' do
      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    it 'assigns @usage_terms correctly' do
      expect(assigns[:usage_terms])
        .to match_array(UsageTerms.all)
    end
  end

  describe '#show' do
    let(:usage_terms) { create :usage_terms }
    before do
      get(
        :show,
        params: { id: usage_terms.id },
        session: { user_id: admin_user.id })
    end

    it 'responds with HTTP 200 status code' do
      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    it 'renders show template' do
      expect(response).to render_template(:show)
    end

    it 'assigns @usage_terms correctly' do
      expect(assigns[:usage_terms]).to eq usage_terms
    end
  end

  describe '#new' do
    before { get :new, session: { user_id: admin_user.id } }

    it 'assigns @usage_terms correctly' do
      expect(assigns[:usage_terms]).to be_an_instance_of(UsageTerms)
      expect(assigns[:usage_terms]).to be_new_record
    end

    it 'renders new template' do
      expect(response).to render_template :new
    end
  end

  describe '#create' do
    let(:usage_terms_params) { attributes_for :usage_terms }

    it 'creates a new usage terms' do
      expect do
        post(
          :create,
          params: { usage_terms: usage_terms_params },
          session: { user_id: admin_user.id })
      end.to change { UsageTerms.count }.by(1)
    end

    it 'redirects to admin vocabularies path' do
      post(
        :create,
        params: { usage_terms: usage_terms_params },
        session: { user_id: admin_user.id })

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(usage_terms_path)
      expect(flash[:success]).to eq flash_message(:create, :success)
    end

    context 'when no params were sent' do
      it 'renders error template' do
        post(
          :create,
          params: {
            usage_terms: {
              title: nil, version: nil,
              intro: nil, body: nil
            }
          },
          session: { user_id: admin_user.id }
        )

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template 'errors/422'
      end
    end
  end

  describe '#destroy' do
    let!(:usage_terms) { create :usage_terms }

    it 'destroys the usage_terms' do
      expect do
        delete(
          :destroy,
          params: { id: usage_terms.id },
          session: { user_id: admin_user.id })
      end.to change { UsageTerms.count }.by(-1)
    end

    context 'when delete was successful' do
      before do
        delete(
          :destroy,
          params: { id: usage_terms.id },
          session: { user_id: admin_user.id })
      end

      it 'redirects to usage terms path' do
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(usage_terms_path)
      end

      it 'sets a correct flash message' do
        expect(flash[:success]).to eq flash_message(:destroy, :success)
      end
    end

    context "when usage terms don't exist" do
      before do
        delete(
          :destroy,
          params: { id: UUIDTools::UUID.random_create },
          session: { user_id: admin_user.id }
        )
      end

      it 'renders error template' do
        expect(response).to have_http_status(404)
        expect(response).to render_template 'errors/404'
      end
    end
  end

  def flash_message(action, type)
    I18n.t type, scope: "flash.actions.#{action}", resource_name: 'Usage terms'
  end
end
