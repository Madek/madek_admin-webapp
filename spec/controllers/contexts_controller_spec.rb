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
          labels: {
            de: 'updated label DE',
            en: 'updated label EN'
          },
          descriptions: {
            de: 'updated description DE',
            en: 'updated description EN'
          },
          admin_comment: 'updated admin comment'
        }
      }

      put :update, params, user_id: admin_user.id

      context.reload

      expect(context.labels['de']).to eq 'updated label DE'
      expect(context.labels['en']).to eq 'updated label EN'
      expect(context.descriptions['de']).to eq 'updated description DE'
      expect(context.descriptions['en']).to eq 'updated description EN'
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

    it 'redirects to context path' do
      post :create, { context: context_params }, user_id: admin_user.id

      expect(response).to have_http_status(302)
      expect(response).to \
        redirect_to(context_path(Context.find(context_params[:id])))
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

  describe '#destroy' do
    let!(:context) { create :context }

    it 'destroys the context' do
      expect { delete :destroy, { id: context.id }, user_id: admin_user.id }
        .to change { Context.count }.by(-1)
    end

    context 'when delete was successful' do
      before { delete :destroy, { id: context.id }, user_id: admin_user.id }

      it 'redirects to admin contexts path' do
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(contexts_path)
      end

      it 'sets a correct flash message' do
        expect(flash[:success]).to eq flash_message(:destroy, :success)
      end
    end

    context "when context doesn't exist" do
      before do
        delete(
          :destroy,
          { id: UUIDTools::UUID.random_create },
          user_id: admin_user.id
        )
      end

      it 'renders error template' do
        expect(response).to have_http_status(404)
        expect(response).to render_template 'errors/404'
      end
    end
  end

  describe '#add_meta_key' do
    let!(:context) { create :context_with_context_keys }
    let(:meta_key) { create :meta_key_title }

    it 'adds a meta key to a context' do
      expect do
        patch(:add_meta_key,
              { id: context.id, meta_key_id: meta_key.id },
              user_id: admin_user.id)
      end.to change { ContextKey.count }.by(1)
    end

    it 'redirects to edit context path' do
      patch(:add_meta_key,
            {
              id: context.id,
              meta_key_id: context.context_keys.first.meta_key_id
            },
            user_id: admin_user.id)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(edit_context_path(context))
      expect(flash[:success]).not_to be_empty
    end
  end

  def flash_message(action, type)
    I18n.t type, scope: "flash.actions.#{action}", resource_name: 'Context'
  end
end
