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

  describe 'changing position' do
    let!(:v1) { create :vocabulary, id: 'order-test-alpha' }
    let!(:hidden) { create :vocabulary, id: 'not-matching-filter' }
    let!(:v2) { create :vocabulary, id: 'order-test-beta' }
    let!(:v3) { create :vocabulary, id: 'order-test-gamma' }

    def order_of(*vocabularies)
      ids = vocabularies.map(&:id)
      Vocabulary.reorder(:position).pluck(:id) & ids
    end

    def move(direction, vocabulary, extra_params = {})
      patch "move_#{direction}",
            params: { id: vocabulary.id }.merge(extra_params),
            session: { user_id: admin_user.id }
    end

    context 'without filter' do
      it '#move_up swaps with the previous vocabulary' do
        move(:up, v2)
        expect(order_of(v1, hidden, v2, v3)).to eq [v1, v2, hidden, v3].map(&:id)
      end

      it '#move_down swaps with the next vocabulary' do
        move(:down, v1)
        expect(order_of(v1, hidden, v2, v3)).to eq [hidden, v1, v2, v3].map(&:id)
      end

      it '#move_to_top moves to the first position of all vocabularies' do
        move(:to_top, v3)
        expect(Vocabulary.reorder(:position).first).to eq v3
      end

      it '#move_to_bottom moves to the last position of all vocabularies' do
        move(:to_bottom, v1)
        expect(Vocabulary.reorder(:position).last).to eq v1
      end

      it '#move_up on the first vocabulary does not change the order' do
        move(:to_top, v1)
        move(:up, v1)
        expect(Vocabulary.reorder(:position).first).to eq v1
      end

      it '#move_down on the last vocabulary does not change the order' do
        move(:to_bottom, v3)
        move(:down, v3)
        expect(Vocabulary.reorder(:position).last).to eq v3
      end

      it '#move_to_top on the first vocabulary does not change the order' do
        move(:to_top, v2)
        before_move = Vocabulary.reorder(:position).pluck(:id)
        move(:to_top, v2)
        expect(Vocabulary.reorder(:position).pluck(:id)).to eq before_move
      end

      it '#move_to_bottom on the last vocabulary does not change the order' do
        move(:to_bottom, v2)
        before_move = Vocabulary.reorder(:position).pluck(:id)
        move(:to_bottom, v2)
        expect(Vocabulary.reorder(:position).pluck(:id)).to eq before_move
      end

      it '#move_to_top keeps the relative order of the others' do
        move(:to_top, v3)
        expect(order_of(v1, hidden, v2, v3)).to eq [v3, v1, hidden, v2].map(&:id)
      end

      it '#move_to_bottom keeps the relative order of the others' do
        move(:to_bottom, v1)
        expect(order_of(v1, hidden, v2, v3)).to eq [hidden, v2, v3, v1].map(&:id)
      end

      it 'a sequence of moves ends in the expected order' do
        move(:down, v1)
        move(:to_top, v3)
        move(:up, v1)
        move(:to_bottom, v3)
        expect(order_of(v1, hidden, v2, v3)).to eq [v1, hidden, v2, v3].map(&:id)
      end

      %i(up down to_top to_bottom).each do |direction|
        it "#move_#{direction} redirects to the vocabularies list with a success flash" do
          move(direction, v2)
          expect(response).to have_http_status(302)
          expect(response).to redirect_to(vocabularies_path)
          expect(flash[:success]).to be_present
        end

        it "#move_#{direction} renders 404 for an unknown vocabulary" do
          patch "move_#{direction}",
                params: { id: 'does-not-exist' },
                session: { user_id: admin_user.id }
          expect(response).to have_http_status(404)
          expect(response).to render_template 'errors/404'
        end
      end

      it 'keeps positions gapless and unique' do
        move(:up, v3)
        move(:to_top, v2)
        move(:to_bottom, hidden)
        positions = Vocabulary.reorder(:position).pluck(:position)
        expect(positions).to eq((0...Vocabulary.count).to_a)
      end
    end

    # Vocabularies are ordered globally. A search term only hides rows,
    # the move still works on the global order.
    context 'with filter (search_term)' do
      it '#move_up swaps with the global neighbour, even if it is hidden by the filter' do
        move(:up, v2, search_term: 'order-test-')
        expect(order_of(v1, hidden, v2, v3)).to eq [v1, v2, hidden, v3].map(&:id)
      end

      it '#move_down swaps with the global neighbour, even if it is hidden by the filter' do
        move(:down, v1, search_term: 'alpha')
        expect(order_of(v1, hidden, v2, v3)).to eq [hidden, v1, v2, v3].map(&:id)
      end

      it '#move_to_top / #move_to_bottom work on the global order' do
        move(:to_top, v3, search_term: 'gamma')
        expect(Vocabulary.reorder(:position).first).to eq v3
        move(:to_bottom, v3, search_term: 'gamma')
        expect(Vocabulary.reorder(:position).last).to eq v3
      end

      it 'redirects to the unfiltered list (search term and page are dropped)' do
        move(:up, v2, search_term: 'order-test-', page: '2')
        expect(response).to redirect_to(vocabularies_path)
      end
    end
  end

  def flash_message(action, type)
    I18n.t type, scope: "flash.actions.#{action}", resource_name: 'Vocabulary'
  end
end
