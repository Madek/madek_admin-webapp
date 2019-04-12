require 'spec_helper'

describe KeywordsController do
  let(:admin_user) { create :admin_user }
  let(:meta_key) { create :meta_key_keywords }
  let(:vocabulary) { meta_key.vocabulary }
  let!(:keyword) { create :keyword, meta_key: meta_key }

  describe '#index' do
    before do
      get :index,
          { vocabulary_id: vocabulary.id },
          user_id: admin_user.id
    end

    it 'responds with HTTP 200 status code' do
      expect(response).to be_success
      expect(response).to have_http_status(200)
    end

    it 'assigns @keywords correctly' do
      expect(assigns[:keywords]).not_to be_empty
    end

    describe 'filtering' do
      context 'by id' do
        it 'returns a proper keyword' do
          get(
            :index,
            { vocabulary_id: vocabulary.id, search_term: keyword.id },
            user_id: admin_user.id
          )

          expect(assigns[:keywords]).to match_array [keyword]
        end
      end

      context 'by term' do
        it 'returns a proper keyword ' do
          get(
            :index,
            { vocabulary_id: vocabulary.id, search_term: keyword.term[0..-2] },
            user_id: admin_user.id
          )

          expect(assigns[:keywords]).to match_array [keyword]
        end
      end

      context 'by meta key' do
        it 'returns a proper keyword' do
          get(
            :index,
            {
              vocabulary_id: vocabulary.id,
              search_term: keyword.meta_key_id
            },
            user_id: admin_user.id
          )

          expect(assigns[:keywords]).to match_array [keyword]
        end
      end

      context 'not used' do
        it 'return proper keywords' do
          mtk = create :meta_datum_keywords
          not_used_keyword = create :keyword, term: 'foo_1'
          used_keyword = mtk.keywords.sample
          used_keyword.update_column(:term, 'foo_2')

          get(
            :index,
            {
              filter: {
                not_used: 1
              },
              search_term: 'foo'
            },
            user_id: admin_user.id
          )

          expect(assigns[:keywords]).to match_array [not_used_keyword]
        end
      end
    end
  end

  describe '#edit' do
    it 'assigns @vocabulary and @keyword correctly' do
      get(
        :edit,
        { vocabulary_id: vocabulary.id, id: keyword.id },
        user_id: admin_user.id
      )

      expect(assigns[:vocabulary]).to eq vocabulary
      expect(assigns[:keyword]).to eq keyword
      expect(response).to render_template :edit
    end
  end

  describe '#update' do
    let(:ext_uris_txt) do
      <<-TEXTAREA
      http://geonames.org/countries/CH/
        https://user:pass@ld.example.com/foo/bar
    TEXTAREA
    end

    let(:ext_uris) do
      ['http://geonames.org/countries/CH/', 'https://ld.example.com/foo/bar']
    end

    let(:params) do
      {
        vocabulary_id: vocabulary.id,
        id: keyword.id,
        keyword: {
          term: 'updated term',
          external_uris: ext_uris_txt
        }
      }
    end

    it 'updates the keyword' do
      put :update, params, user_id: admin_user.id
      kw = keyword.reload
      expect(kw.term).to eq 'updated term'
      expect(kw.external_uris).to eq ext_uris
      expect(flash[:success]).to eq flash_message(:update, :success)
    end

    it 'redirects to admin keyword path' do
      put :update, params, user_id: admin_user.id

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(
        keywords_path(filter: { vocabulary_id: vocabulary })
      )
    end
  end

  describe '#new' do
    before { get :new, { vocabulary_id: vocabulary.id }, user_id: admin_user.id }

    it 'assigns @vocabulary correctly' do
      expect(assigns[:vocabulary]).to eq vocabulary
    end

    it 'assigns @keyword correctly' do
      expect(assigns[:keyword]).to be_an_instance_of(Keyword)
      expect(assigns[:keyword]).to be_new_record
    end

    it 'renders new template' do
      expect(response).to render_template :new
    end
  end

  describe '#create' do
    let(:keyword_params) do
      {
        vocabulary_id: vocabulary.id,
        keyword: {
          term: 'new keyword',
          meta_key_id: meta_key.id
        }
      }
    end

    it 'creates a new keyword' do
      expect { post :create, keyword_params, user_id: admin_user.id }
        .to change { Keyword.count }.by(1)
    end

    it 'redirects to admin keywords path' do
      post :create, keyword_params, user_id: admin_user.id

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(
        keywords_path(filter: { vocabulary_id: vocabulary })
      )
      expect(flash[:success]).not_to be_empty
    end

    it 'displays success message' do
      post :create, keyword_params, user_id: admin_user.id

      expect(flash[:success]).not_to be_empty
    end
  end

  describe '#destroy' do
    it 'destroys the keyword' do
      vocabulary and keyword

      expect do
        delete(
          :destroy,
          { vocabulary_id: vocabulary.id, id: keyword.id },
          user_id: admin_user.id
        )
      end.to change { Keyword.count }.by(-1)
    end

    context 'when delete was successful' do
      before do
        delete(
          :destroy,
          { vocabulary_id: vocabulary.id, id: keyword.id },
          user_id: admin_user.id
        )
      end

      it 'redirects to admin keywords path' do
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(
          keywords_path(filter: { vocabulary_id: vocabulary })
        )
      end

      it 'displays success message' do
        expect(flash[:success]).to be_present
      end
    end

    context 'when keyword does not exist' do
      it 'renders error template' do
        delete(
          :destroy,
          {
            vocabulary_id: vocabulary.id,
            id: UUIDTools::UUID.random_create
          },
          user_id: admin_user.id
        )

        expect(response).to have_http_status(:not_found)
        expect(response).to render_template 'errors/404'
      end
    end
  end

  describe '#form_merge_to' do
    before(:each) do
      get :form_merge_to, { id: keyword.id }, user_id: admin_user.id
    end

    it 'assigns variables correctly' do
      expect(assigns[:keyword]).to eq keyword
    end

    it 'renders template' do
      expect(response).to have_http_status(200)
      expect(response).to render_template :form_merge_to
    end
  end

  describe '#merge_to' do
    let(:receiver) { create :keyword, meta_key: meta_key }
    before(:each) do
      allow_any_instance_of(Keyword).to receive(:merge_to)
    end

    context 'when receiver ID is the same as originator ID' do
      before(:each) do
        post(
          :merge_to,
          { id: keyword.id, id_receiver: keyword.id },
          user_id: admin_user.id
        )
      end

      it 'redirects back' do
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(form_merge_to_keyword_path(keyword))
      end

      it 'displays error flash' do
        expect(flash[:error]).to be_present
      end
    end

    context 'when receiver ID is not the same as originator ID' do
      before(:each) do
        post(
          :merge_to,
          { id: keyword.id,
            id_receiver: receiver.id,
            redirect_to: '/redirected-to'
          },
          user_id: admin_user.id
        )
      end

      it 'redirects to path from param' do
        expect(response).to have_http_status(302)
        expect(response).to redirect_to('/redirected-to')
      end

      it 'displays success message' do
        expect(flash[:success]).to be_present
      end
    end
  end

  describe '#usage' do
    it 'responds with HTTP 200 status code' do
      expect(response).to be_success
      expect(response).to have_http_status(200)
    end

    it 'assigns variables correctly' do
      get :usage, { id: keyword.id }, user_id: admin_user.id

      expect(assigns[:keyword]).to eq keyword
      expect(assigns[:usage_count]).to eq 0
      expect(assigns[:media_entries]).to be
    end
  end

  def flash_message(action, type)
    I18n.t type, scope: "flash.actions.#{action}", resource_name: 'Keyword'
  end
end
