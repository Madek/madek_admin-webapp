require 'spec_helper'

describe ContextsController do
  let(:admin_user) { create :admin_user }

  describe '#index' do
    before { get :index, nil, user_id: admin_user.id }

    it 'responds with HTTP 200 status code' do
      expect(response).to be_success
      expect(response).to have_http_status(200)
    end

    it 'assigns @contexts correctly' do
      expect(assigns[:contexts])
        .to match_array(Context.all)
    end
  end

  describe '#show' do
    let(:context) { create :context_with_context_keys }
    before { get :show, { id: context.id }, user_id: admin_user.id }

    it 'responds with HTTP 200 status code' do
      expect(response).to be_success
      expect(response).to have_http_status(200)
    end

    it 'assigns @context correctly' do
      expect(assigns[:context]).to eq context
    end

    it 'assigns @context.context_keys correctly' do
      expect(assigns[:context].context_keys).to match_array(context.context_keys)
    end
  end

  describe '#edit' do
    let(:context) { create :context }
    before { get :edit, { id: context.id }, user_id: admin_user.id }

    it 'assigns @context correctly' do
      expect(assigns[:context]).to eq context
      expect(response).to render_template :edit
    end
  end

  describe '#update' do
    let(:context) { create :context }

    it 'updates the context' do
      params = {
        id: context.id,
        context: {
          label: 'updated label',
          description: 'updated description',
          admin_comment: 'updated admin comment'
        }
      }

      put :update, params, user_id: admin_user.id

      context.reload

      expect(context.label).to eq 'updated label'
      expect(context.description).to eq 'updated description'
      expect(context.admin_comment).to eq 'updated admin comment'
      expect(flash[:success]).to eq flash_message(:update, :success)
    end

    it 'does not update the id' do
      previous_id = context.id

      put(
        :update,
        {
          id: context.id,
          context: { id: Faker::Internet.slug }
        },
        user_id: admin_user.id
      )

      expect(context.reload.id).to eq previous_id
    end
  end

  describe '#new' do
    before { get :new, nil, user_id: admin_user.id }

    it 'assigns @context correctly' do
      expect(assigns[:context]).to be_an_instance_of(Context)
      expect(assigns[:context]).to be_new_record
    end

    it 'renders new template' do
      expect(response).to render_template :new
    end
  end

  describe '#create' do
    let(:context_params) { attributes_for :context }

    it 'creates a new Context' do
      expect do
        post :create, { context: context_params }, user_id: admin_user.id
      end.to change { Context.count }.by(1)
    end

    it 'redirects to contexts path' do
      post :create, { context: context_params }, user_id: admin_user.id

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(contexts_path)
      expect(flash[:success]).to eq flash_message(:create, :success)
    end

    context 'when Context with given ID already exists' do
      let!(:context) { create :context, id: context_params[:id] }

      it 'renders error template' do
        post :create, { context: context_params }, user_id: admin_user.id

        expect(response).to have_http_status(500)
        expect(response).to render_template 'errors/500'
      end
    end

    context 'when no params were sent' do
      it 'renders error template' do
        post(
          :create,
          {
            context: { id: nil, label: nil, description: nil }
          },
          user_id: admin_user.id
        )

        expect(response).to have_http_status(:internal_server_error)
        expect(response).to render_template 'errors/500'
      end
    end
  end

  def flash_message(action, type)
    I18n.t type, scope: "flash.actions.#{action}", resource_name: 'Context'
  end
end
