require 'spec_helper'

describe ContextKeysController do
  let(:admin_user) { create :admin_user }

  describe '#edit' do
    let(:context_key) { create :context_key }
    before { get :edit, { id: context_key.id }, user_id: admin_user.id }

    it 'assigns @context_key correctly' do
      expect(assigns[:context_key]).to eq context_key
      expect(response).to render_template :edit
    end
  end

  describe '#update' do
    let(:context_key) { create :context_key }

    it 'updates the context key' do
      params = {
        id: context_key.id,
        context_key: {
          label: 'updated label',
          description: 'updated description',
          hint: 'updated hint',
          admin_comment: 'updated admin comment',
          is_required: true,
          length_min: 0,
          length_max: 254,
          input_type: 'text_area'
        }
      }

      put :update, params, user_id: admin_user.id

      context_key.reload

      expect(context_key.label).to eq 'updated label'
      expect(context_key.description).to eq 'updated description'
      expect(context_key.hint).to eq 'updated hint'
      expect(context_key.admin_comment).to eq 'updated admin comment'
      expect(context_key.is_required).to be true
      expect(context_key.length_min).to be_zero
      expect(context_key.length_max).to eq 254
      expect(context_key.input_type).to eq 'text_area'
      expect(flash[:success]).to eq flash_message(:update, :success)
    end

    it 'does not update the id' do
      previous_id = context_key.id

      put(
        :update,
        {
          id: context_key.id,
          context_key: { id: Faker::Internet.slug }
        },
        user_id: admin_user.id
      )

      expect(context_key.reload.id).to eq previous_id
    end
  end

  describe '#move_up' do
    let(:context_key) { create :context_key }
    before { patch :move_up, { id: context_key.id }, user_id: admin_user.id }

    it 'it redirects to a proper context path' do
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(context_path(context_key.context))
    end

    it 'sets a success flash message' do
      expect(flash[:success]).to be_present
    end

    context 'when Context Key does not exist' do
      it 'renders error template' do
        patch :move_up,
              { id: UUIDTools::UUID.random_create },
              user_id: admin_user.id

        expect(response).to have_http_status(404)
        expect(response).to render_template 'errors/404'
      end
    end
  end

  describe '#move_down' do
    let(:context_key) { create :context_key }
    before { patch :move_down, { id: context_key.id }, user_id: admin_user.id }

    it 'it redirects to a proper context path' do
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(context_path(context_key.context))
    end

    it 'sets a success flash message' do
      expect(flash[:success]).to be_present
    end

    context 'when ID is missing' do
      it 'renders error template' do
        patch :move_down, { id: '' }, user_id: admin_user.id

        expect(response).to have_http_status(404)
        expect(response).to render_template 'errors/404'
      end
    end
  end

  def flash_message(action, type)
    I18n.t type, scope: "flash.actions.#{action}", resource_name: 'Context key'
  end
end
