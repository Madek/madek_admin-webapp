require 'spec_helper'

describe VocabulariesController do
  let(:admin_user) { create :admin_user }

  describe '#index' do
    before { get :index, session: { user_id: admin_user.id } }

    it 'responds with HTTP 200 status code' do
      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    it 'assigns @vocabularies correctly' do
      expect(assigns[:vocabularies])
        .to match_array(Vocabulary.with_meta_keys_count.limit(16))
    end

    describe 'filtering' do
      context 'by id' do
        it 'returns a proper vocabulary' do
          vocabulary = create :vocabulary, id: 'sample_id'

          get(
            :index,
            params: { search_term: 'sample_id' },
            session: { user_id: admin_user.id })

          expect(assigns[:vocabularies]).to eq [vocabulary]
        end
      end

      context 'by label' do
        it "returns vocabularies containing 'aaa' in labels" do
          first_vocabulary = create :vocabulary, labels: { de: 'saaample label' }
          second_vocabulary = create :vocabulary, labels: { de: 'sample laaabel' }

          get(
            :index,
            params: { search_term: 'aaa' },
            session: { user_id: admin_user.id })

          expect(assigns[:vocabularies]).to \
            match_array([first_vocabulary, second_vocabulary])
        end
      end
    end
  end

  describe '#show' do
    let(:vocabulary) { create :vocabulary }
    before do
      get(
        :show,
        params: { id: vocabulary.id },
        session: { user_id: admin_user.id })
    end

    it 'responds with HTTP 200 status code' do
      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    it 'assigns @vocabulary correctly' do
      expect(assigns[:vocabulary]).to eq vocabulary
    end

    it 'assigns @meta_keys correctly' do
      expect(assigns[:meta_keys]).not_to be_nil
    end
  end

  describe '#edit' do
    let(:vocabulary) { create :vocabulary }
    before do
      get :edit, params: { id: vocabulary.id }, session: { user_id: admin_user.id }
    end

    it 'assigns @vocabulary correctly' do
      expect(assigns[:vocabulary]).to eq vocabulary
      expect(response).to render_template :edit
    end

    it 'assigns @meta_keys correctly' do
      expect(assigns[:meta_keys]).not_to be_nil
    end
  end

  describe '#update' do
    let(:vocabulary) { create :vocabulary }

    it 'updates the vocabulary' do
      params = {
        id: vocabulary.id,
        vocabulary: {
          labels: {
            de: 'updated label DE',
            en: 'updated label EN'
          },
          descriptions: {
            de: 'updated description DE',
            en: 'updated description EN'
          },
          admin_comment: 'updated admin comment',
          enabled_for_public_view: false,
          enabled_for_public_use: false
        }
      }

      put :update, params: params, session: { user_id: admin_user.id }

      vocabulary.reload

      expect(vocabulary.labels['de']).to eq 'updated label DE'
      expect(vocabulary.labels['en']).to eq 'updated label EN'
      expect(vocabulary.descriptions['de']).to eq 'updated description DE'
      expect(vocabulary.descriptions['en']).to eq 'updated description EN'
      expect(vocabulary.admin_comment).to eq 'updated admin comment'
      expect(vocabulary.enabled_for_public_view).to be false
      expect(vocabulary.enabled_for_public_use).to be false
      expect(flash[:success]).to eq flash_message(:update, :success)
    end

    it 'does not update the id' do
      remember_id = vocabulary.id

      put(
        :update,
        params: {
          id: vocabulary.id,
          vocabulary: { id: Faker::Internet.slug }
        },
        session: { user_id: admin_user.id }
      )

      expect(vocabulary.reload.id).to eq remember_id
    end
  end

  describe '#new' do
    before { get :new, session: { user_id: admin_user.id } }

    it 'assigns @vocabulary correctly' do
      expect(assigns[:vocabulary]).to be_an_instance_of(Vocabulary)
      expect(assigns[:vocabulary]).to be_new_record
    end

    it 'renders new template' do
      expect(response).to render_template :new
    end
  end

  describe '#create' do
    let(:vocabulary_params) { attributes_for :vocabulary }

    it 'creates a new vocabulary' do
      expect do
        post(
          :create,
          params: { vocabulary: vocabulary_params },
          session: { user_id: admin_user.id })
      end.to change { Vocabulary.count }.by(1)
    end

    it 'redirects to admin vocabularies path' do
      post(
        :create,
        params: { vocabulary: vocabulary_params },
        session: { user_id: admin_user.id })

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(vocabularies_path)
      expect(flash[:success]).to eq flash_message(:create, :success)
    end

    context 'when vocabulary with ID already exists' do
      let!(:vocabulary) { create :vocabulary, id: vocabulary_params[:id] }

      it 'renders error template' do
        post(
          :create,
          params: { vocabulary: vocabulary_params },
          session: { user_id: admin_user.id })

        expect(response).to have_http_status(500)
        expect(response).to render_template 'errors/500'
      end
    end

    context 'when no params were sent' do
      it 'renders error template' do
        post(
          :create,
          params: {
            vocabulary: { id: nil, labels: {}, descriptions: {} }
          },
          session: { user_id: admin_user.id }
        )

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template 'errors/422'
      end
    end
  end

  describe '#destroy' do
    let!(:vocabulary) { create :vocabulary }

    it 'destroys the vocabulary' do
      expect do
        delete(
          :destroy,
          params: { id: vocabulary.id },
          session: { user_id: admin_user.id })
      end.to change { Vocabulary.count }.by(-1)
    end

    context 'when delete was successful' do
      before do
        delete(
          :destroy,
          params: { id: vocabulary.id },
          session: { user_id: admin_user.id })
      end

      it 'redirects to admin vocabularies path' do
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(vocabularies_path)
      end

      it 'sets a correct flash message' do
        expect(flash[:success]).to eq flash_message(:destroy, :success)
      end
    end

    context "when vocabulary doesn't exist" do
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

  describe '#move_up' do
    let(:vocabulary) { create :vocabulary }
    before do
      patch(
        :move_up,
        params: { id: vocabulary.id },
        session: { user_id: admin_user.id })
    end

    it 'it redirects to admin vocabularies path' do
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(vocabularies_path)
    end

    it 'sets a success flash message' do
      expect(flash[:success]).to be_present
    end

    context 'when Vocabulary does not exist' do
      it 'renders error template' do
        patch :move_up,
              params: { id: UUIDTools::UUID.random_create },
              session: { user_id: admin_user.id }

        expect(response).to have_http_status(404)
        expect(response).to render_template 'errors/404'
      end
    end
  end

  describe '#move_down' do
    let(:vocabulary) { create :vocabulary }
    before do
      patch(
        :move_down,
        params: { id: vocabulary.id },
        session: { user_id: admin_user.id })
    end

    it 'it redirects to admin vocabularies path' do
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(vocabularies_path)
    end

    it 'sets a success flash message' do
      expect(flash[:success]).to be_present
    end

    context 'when ID is missing' do
      it 'renders error template' do
        patch :move_down, params: { id: '' }, session: { user_id: admin_user.id }

        expect(response).to have_http_status(404)
        expect(response).to render_template 'errors/404'
      end
    end
  end

  def flash_message(action, type)
    I18n.t type, scope: "flash.actions.#{action}", resource_name: 'Vocabulary'
  end
end
