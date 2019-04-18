require 'spec_helper'

describe MetaKeysController do
  let(:admin_user) { create :admin_user }

  describe '#index' do
    it 'responds with 200 HTTP status code' do
      get :index, session: { user_id: admin_user.id }

      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    context 'filtering by meta datum object type' do
      it 'assigns @meta_keys properly filtered' do
        meta_key_title = create :meta_key_title
        create :meta_key_people
        type_param = meta_key_title.meta_datum_object_type

        get(
          :index,
          params: { type: type_param },
          session: { user_id: admin_user.id }
        )

        assigns[:meta_keys].each do |meta_key|
          expect(meta_key.meta_datum_object_type).to eq type_param
        end
      end
    end

    context 'filtering by ID' do
      it 'returns correct collection of meta keys' do
        meta_key_1 = create :meta_key_title, id: 'test:bar_foo'
        meta_key_2 = create :meta_key_title, id: 'test:foo_bar'

        get(
          :index,
          params: { search_term: 'foo' },
          session: { user_id: admin_user.id })

        expect(assigns[:meta_keys]).to match_array([meta_key_1, meta_key_2])
      end
    end

    context 'filtering by label' do
      it 'returns correct collection of meta keys' do
        meta_key_1 = create :meta_key_title, labels: { de: 'foo:bar' }
        meta_key_2 = create :meta_key_keywords, labels: { de: 'bar:foo' }

        get(
          :index,
          params: { search_term: 'bar' },
          session: { user_id: admin_user.id })

        expect(assigns[:meta_keys]).to match_array([meta_key_1, meta_key_2])
      end
    end

    context 'filtering by vocabulary' do
      it 'returns correct collection of meta keys' do
        vocabulary = create :vocabulary
        meta_key_1 = create(:meta_key_keywords,
                            id: "#{vocabulary}:meta_key_1",
                            vocabulary: vocabulary)
        meta_key_2 = create(:meta_key_keywords,
                            id: "#{vocabulary}:meta_key_2",
                            vocabulary: vocabulary)
        create :meta_key_keywords

        get(
          :index,
          params: { vocabulary_id: vocabulary.id },
          session: { user_id: admin_user.id }
        )

        expect(assigns[:meta_keys]).to match_array([meta_key_1, meta_key_2])
      end
    end

    context 'sorting by ID' do
      it 'returns correctly sorted collection of meta keys' do
        meta_key_1 = create :meta_key_title, labels: { de: 'foo:bar' }
        meta_key_2 = create :meta_key_keywords, labels: { de: 'bar:foo' }

        get(
          :index,
          params: { search_term: 'foo' },
          session: { user_id: admin_user.id })

        expect(assigns[:meta_keys]).to match_array [meta_key_2, meta_key_1]
      end
    end

    context 'sorting by Name part' do
      it 'returns correctly sorted collection of meta keys' do
        meta_key_1 = create :meta_key_title, labels: { de: 'foo:project_type' }
        meta_key_2 = create :meta_key_keywords, labels: { de: 'foo:academic_year' }

        get(:index,
            params: {
              search_term: 'foo',
              sort_by: :name_part
            },
            session: { user_id: admin_user.id })

        expect(assigns[:meta_keys]).to match_array [meta_key_2, meta_key_1]
      end
    end
  end

  describe '#edit' do
    let(:meta_key) { create :meta_key_title }
    before do
      get(
        :edit,
        params: { id: meta_key.id },
        session: { user_id: admin_user.id })
    end

    it 'responds with 200 HTTP status code' do
      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    it 'assigns @meta_key correctly' do
      expect(assigns[:meta_key]).to eq meta_key
    end

    context 'when meta key belongs to madek_core Vocabulary' do
      let(:meta_key) do
        MetaKey.find_by(id: 'madek_core:title') || create(:meta_key_core_title)
      end

      it 'renders forbidden notice' do
        expect(response).to have_http_status(:forbidden)
        expect(response.body).to eq 'Error 403 - Admin access denied!'
      end
    end
  end

  describe '#update' do
    let(:meta_key) { create :meta_key_title }
    let(:meta_key_params) do
      {
        labels: { de: 'label DE', en: 'label EN' },
        descriptions: { de: 'description DE', en: 'description EN' },
        hints: { de: 'hint DE', en: 'hint EN' },
        meta_datum_object_type: 'MetaDatum::Text',
        is_extensible_list: true,
        is_enabled_for_media_entries: true,
        is_enabled_for_collections: true,
        keywords_alphabetical_order: true,
        text_type: 'block'
      }
    end
    before do
      patch(
        :update,
        params: { id: meta_key.id, meta_key: meta_key_params },
        session: { user_id: admin_user.id }
      )
    end

    it 'redirects to meta key path' do
      expect(response).to redirect_to meta_key_path(meta_key)
    end

    it 'displays success message' do
      expect(flash[:success]).to eq flash_message(:update, :success)
    end

    it 'updates the meta key' do
      meta_key.reload
      expect(meta_key.label).to eq 'label DE'
      expect(meta_key.label(:de)).to eq 'label DE'
      expect(meta_key.label(:en)).to eq 'label EN'
      expect(meta_key.description).to eq 'description DE'
      expect(meta_key.description(:de)).to eq 'description DE'
      expect(meta_key.description(:en)).to eq 'description EN'
      expect(meta_key.hint).to eq 'hint DE'
      expect(meta_key.hint(:de)).to eq 'hint DE'
      expect(meta_key.hint(:en)).to eq 'hint EN'
      expect(meta_key.meta_datum_object_type).to eq 'MetaDatum::Text'
      expect(meta_key.is_extensible_list).to be true
      expect(meta_key.is_enabled_for_media_entries).to be true
      expect(meta_key.is_enabled_for_collections).to be true
      expect(meta_key.keywords_alphabetical_order).to be true
      expect(meta_key.text_type).to eq 'block'
    end

    context 'when type is MetaDatum::People' do
      it 'sanitizes allowed_people_subtypes' do
        meta_key = create(:meta_key_people)

        patch(
          :update,
          params: {
            id: meta_key.id,
            meta_key: {
              allowed_people_subtypes: ['', 'Person', '']
            }
          },
          session: { user_id: admin_user.id }
        )

        expect(meta_key.reload.allowed_people_subtypes).to eq(['Person'])
      end
    end

    context 'when meta key belongs to madek_core Vocabulary' do
      let(:meta_key) do
        MetaKey.find_by(id: 'madek_core:title') || create(:meta_key_core_title)
      end

      it 'renders forbidden notice' do
        expect(response).to have_http_status(:forbidden)
        expect(response.body).to eq 'Error 403 - Admin access denied!'
      end
    end
  end

  describe '#show' do
    let(:meta_key) { create :meta_key_title }
    let(:keyword) { create :keyword, meta_key: meta_key }
    before do
      get :show, params: { id: meta_key.id }, session: { user_id: admin_user.id }
    end

    it 'responds with the success' do
      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    it 'renders show template' do
      expect(response).to render_template :show
    end

    it 'assigns variables correctly' do
      expect(assigns[:meta_key]).to eq meta_key
      expect(assigns[:keywords]).to eq [keyword]
      expect(assigns[:usage_counts]).to be_a(Hash)
    end
  end

  describe '#destroy' do
    let!(:meta_key) { create :meta_key_title }

    it 'redirects to admin meta keys path' do
      delete(
        :destroy,
        params: { id: meta_key.id },
        session: { user_id: admin_user.id })

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(meta_keys_path)
    end

    it 'deletes the meta key' do
      expect do
        delete(
          :destroy,
          params: { id: meta_key.id },
          session: { user_id: admin_user.id })
      end.to change { MetaKey.count }.by(-1)
    end

    it 'sets correct flash message' do
      delete(
        :destroy,
        params: { id: meta_key.id },
        session: { user_id: admin_user.id })

      expect(flash[:success]).to eq flash_message(:destroy, :success)
    end

    context 'when a meta key does not exist' do
      it 'renders error page' do
        delete :destroy, params: { id: 123 }, session: { user_id: admin_user.id }

        expect(response).to have_http_status(404)
        expect(response).to render_template 'errors/404'
      end
    end

    context 'when meta key belongs to madek_core Vocabulary' do
      let(:meta_key) do
        MetaKey.find_by(id: 'madek_core:title') || create(:meta_key_core_title)
      end

      it 'renders forbidden notice' do
        delete(
          :destroy,
          params: { id: meta_key.id },
          session: { user_id: admin_user.id })

        expect(response).to have_http_status(:forbidden)
        expect(response.body).to eq 'Error 403 - Admin access denied!'
      end
    end
  end

  describe '#new' do
    before { get :new, session: { user_id: admin_user.id } }

    it 'assigns @meta_key correctly' do
      expect(assigns[:meta_key]).to be_instance_of(MetaKey)
    end

    it 'renders new template' do
      expect(response).to render_template :new
    end
  end

  describe '#create' do
    let(:vocabulary) { create :vocabulary }
    let(:meta_key_params) do
      {
        id: "#{vocabulary}:test",
        labels: { de: 'label DE', en: 'label EN' },
        descriptions: { de: 'description DE', en: 'description EN' },
        hints: { de: 'hint DE', en: 'hint EN' },
        vocabulary_id: vocabulary.id,
        is_extensible_list: true,
        is_enabled_for_media_entries: true,
        is_enabled_for_collections: true
      }
    end

    it 'creates a new meta key' do
      expect do
        post(
          :create,
          params: { meta_key: meta_key_params },
          session: { user_id: admin_user.id })
      end.to change { MetaKey.count }.by(1)
    end

    it 'redirects to edit admin meta key path' do
      post(
        :create,
        params: { meta_key: meta_key_params },
        session: { user_id: admin_user.id })

      meta_key = MetaKey.find(meta_key_params[:id])

      expect(response).to redirect_to edit_meta_key_path(meta_key)
    end

    it 'sets a success message correctly' do
      post(
        :create,
        params: { meta_key: meta_key_params },
        session: { user_id: admin_user.id })

      expect(flash[:success]).to eq flash_message(:create, :success)
    end

    it 'sets boolean fields correctly' do
      post(
        :create,
        params: { meta_key: meta_key_params },
        session: { user_id: admin_user.id })

      meta_key = MetaKey.find(meta_key_params[:id])

      expect(meta_key.is_extensible_list).to be true
      expect(meta_key.is_enabled_for_media_entries).to be true
      expect(meta_key.is_enabled_for_collections).to be true
      expect(meta_key.keywords_alphabetical_order).to be true
    end

    it 'sets localized fields correctly' do
      post(
        :create,
        params: { meta_key: meta_key_params },
        session: { user_id: admin_user.id })

      meta_key = MetaKey.find(meta_key_params[:id])

      expect(meta_key.label).to eq 'label DE'
      expect(meta_key.label(:de)).to eq 'label DE'
      expect(meta_key.label(:en)).to eq 'label EN'
      expect(meta_key.description).to eq 'description DE'
      expect(meta_key.description(:de)).to eq 'description DE'
      expect(meta_key.description(:en)).to eq 'description EN'
      expect(meta_key.hint).to eq 'hint DE'
      expect(meta_key.hint(:de)).to eq 'hint DE'
      expect(meta_key.hint(:en)).to eq 'hint EN'
    end
  end

  %i(to_top up down to_bottom).each do |direction|
    describe "#move_#{direction}" do
      let(:meta_key) { create :meta_key_text }
      before do
        patch(
          "move_#{direction}",
          params: { id: meta_key.id },
          session: { user_id: admin_user.id })
      end

      it 'it redirects to admin vocabulary path' do
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(
          edit_vocabulary_path(meta_key.vocabulary))
      end

      it 'sets a success flash message' do
        expect(flash[:success]).to be_present
      end

      context 'when ID is missing' do
        it 'renders error template' do
          patch(
            "move_#{direction}",
            params: { id: '' },
            session: { user_id: admin_user.id })

          expect(response).to have_http_status(404)
          expect(response).to render_template 'errors/404'
        end
      end

      context 'when meta key belongs to madek_core Vocabulary' do
        let(:meta_key) do
          MetaKey.find_by(id: 'madek_core:title') || create(:meta_key_core_title)
        end

        it 'renders forbidden notice' do
          expect(response).to have_http_status(:forbidden)
          expect(response.body).to eq 'Error 403 - Admin access denied!'
        end
      end
    end
  end

  def flash_message(action, type)
    I18n.t type, scope: "flash.actions.#{action}", resource_name: 'Meta key'
  end
end
