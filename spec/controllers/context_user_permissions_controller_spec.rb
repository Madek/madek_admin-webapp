require 'spec_helper'

describe ContextUserPermissionsController do
  let(:admin_user) { create :admin_user }
  let(:context) { create :context }

  describe '#index' do
    let(:first_user_permission) do
      create(:context_user_permission, context: context)
    end
    let(:second_user_permission) do
      create(:context_user_permission, context: context)
    end
    before do
      get(
        :index,
        params: { context_id: context.id },
        session: { user_id: admin_user.id })
    end

    it 'responds with HTTP 200 status code' do
      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    it 'assigns @user_permissions correctly' do
      expect(assigns[:user_permissions]).to match_array(
        [first_user_permission, second_user_permission])
    end
  end

  describe '#new' do
    let(:new_user) { create(:user) }

    it 'assigns locals correctly' do
      get(
        :new,
        params: { context_id: context.id },
        session: { user_id: admin_user.id })

      expect(assigns[:context]).to eq context
      expect(assigns[:permission]).to be_an_instance_of(
        Permissions::ContextUserPermission)
    end

    it "assigns user_id value of permission's instance from params" do
      get(:new,
          params: {
            context_id: context.id,
            user_id: new_user.id
          },
          session: { user_id: admin_user.id })

      expect(assigns[:permission].user_id).to eq new_user.id
    end

    it 'renders new template' do
      get(:new,
          params: { context_id: context.id },
          session: { user_id: admin_user.id })

      expect(response).to render_template(:new)
    end
  end

  describe '#create' do
    it 'creates a permission correctly' do
      expect do
        post(:create,
             params: {
               context_id: context.id,
               context_user_permission: { user_id: create(:user).id }
             },
             session: { user_id: admin_user.id })
      end.to change { Permissions::ContextUserPermission.count }.by(1)
    end

    it 'reset session context_permission_context_id key' do
      session[:context_permission_context_id] = 123

      post(:create,
           params: {
             context_id: context.id,
             context_user_permission: { user_id: create(:user).id }
           },
           session: { user_id: admin_user.id })

      expect(session[:context_permission_context_id]).to be_nil
    end

    it 'redirects to admin context user permissions path' do
      post(:create,
           params: {
             context_id: context.id,
             context_user_permission: { user_id: create(:user).id }
           },
           session: { user_id: admin_user.id })

      expect(response).to redirect_to(
        context_context_user_permissions_url(context))
    end

    it 'sets a correct flash message' do
      post(:create,
           params: {
             context_id: context.id,
             context_user_permission: { user_id: create(:user).id }
           },
           session: { user_id: admin_user.id })

      expect(flash[:success]).to eq(
        'The Context User Permission has been created.')
    end
  end

  describe '#edit' do
    let(:permission) do
      create(:context_user_permission, context: context)
    end
    let(:new_user) { create(:user) }

    it 'assigns locals correctly' do
      get(:edit,
          params: {
            context_id: context.id,
            id: permission.id
          },
          session: { user_id: admin_user.id })

      expect(assigns[:context]).to eq context
      expect(assigns[:permission]).to eq permission
    end

    it "assigns user_id value of permission's instance from params" do
      get(:edit,
          params: {
            context_id: context.id,
            id: permission.id,
            user_id: new_user.id
          },
          session: { user_id: admin_user.id })

      expect(assigns[:permission].user_id).to eq new_user.id
    end
  end

  describe '#update' do
    let(:permission) do
      create(:context_user_permission,
             context: context,
             use: false,
             view: true)
    end
    before do
      patch :update,
            params: {
              context_user_permission: {
                user_id: admin_user.id,
                use: true,
                view: false
              },
              context_id: context.id,
              id: permission.id
            },
            session: { user_id: admin_user.id }
    end

    it 'updates the permission' do
      permission.reload

      expect(permission.user_id).to eq admin_user.id
      expect(permission.use).to be true
      expect(permission.view).to be false
    end

    it 'redirects to context user permissions path' do
      expect(response).to redirect_to(
        context_context_user_permissions_url(context))
      expect(flash[:success]).to eq(
        'The Context User Permission has been updated.')
    end
  end

  describe '#destroy' do
    it 'deletes the permission' do
      permission = create(:context_user_permission, context: context)

      expect do
        delete(
          :destroy,
          params: { context_id: context.id, id: permission.id },
          session: { user_id: admin_user.id }
        )
      end.to change { Permissions::ContextUserPermission.count }.by(-1)
    end
  end
end
