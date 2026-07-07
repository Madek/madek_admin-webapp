require 'spec_helper'

describe ContextGroupPermissionsController do
  let(:admin_user) { create :admin_user }
  let(:context) { create :context }

  describe '#index' do
    let(:first_group_permission) do
      create(:context_group_permission, context: context)
    end
    let(:second_group_permission) do
      create(:context_group_permission, context: context)
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

    it 'assigns @group_permissions correctly' do
      expect(assigns[:group_permissions]).to match_array(
        [first_group_permission, second_group_permission])
    end
  end

  describe '#new' do
    let(:new_group) { create(:group) }

    it 'assigns locals correctly' do
      get(
        :new,
        params: { context_id: context.id },
        session: { user_id: admin_user.id })

      expect(assigns[:context]).to eq context
      expect(assigns[:permission]).to be_an_instance_of(
        Permissions::ContextGroupPermission)
    end

    it "assigns group_id value of permission's instance from params" do
      get(:new,
          params: { context_id: context.id, group_id: new_group.id },
          session: { user_id: admin_user.id })

      expect(assigns[:permission].group_id).to eq new_group.id
    end

    it 'renders new template' do
      get(
        :new,
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
               context_group_permission: { group_id: create(:group).id } },
             session: { user_id: admin_user.id })
      end.to change { Permissions::ContextGroupPermission.count }.by(1)
    end

    it 'reset session context_permission_context_id key' do
      session[:context_permission_context_id] = 123

      post(:create,
           params: {
             context_id: context.id,
             context_group_permission: { group_id: create(:group).id }
           },
           session: { user_id: admin_user.id })

      expect(session[:context_permission_context_id]).to be_nil
    end

    it 'redirects to admin context group permissions path' do
      post(:create,
           params: {
             context_id: context.id,
             context_group_permission: { group_id: create(:group).id } },
           session: { user_id: admin_user.id })

      expect(response).to redirect_to(
        context_context_group_permissions_url(context))
    end

    it 'sets a correct flash message' do
      post(:create,
           params: {
             context_id: context.id,
             context_group_permission: { group_id: create(:group).id } },
           session: { user_id: admin_user.id })

      expect(flash[:success]).to eq(
        'The Context Group Permission has been created.')
    end
  end

  describe '#edit' do
    let(:permission) do
      create(:context_group_permission, context: context)
    end
    let(:new_group) { create(:group) }

    it 'assigns locals correctly' do
      get(:edit,
          params: { context_id: context.id, id: permission.id },
          session: { user_id: admin_user.id })

      expect(assigns[:context]).to eq context
      expect(assigns[:permission]).to eq permission
    end

    it "assigns user_id value of permission's instance from params" do
      get(:edit,
          params: {
            context_id: context.id,
            id: permission.id,
            group_id: new_group.id },
          session: { user_id: admin_user.id })

      expect(assigns[:permission].group_id).to eq new_group.id
    end
  end

  describe '#update' do
    let(:permission) do
      create(:context_group_permission,
             context: context,
             use: false,
             view: true)
    end
    let(:new_group) { create(:group) }

    before do
      patch :update,
            params: {
              context_group_permission: {
                group_id: new_group.id,
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

      expect(permission.group_id).to eq new_group.id
      expect(permission.use).to be true
      expect(permission.view).to be false
    end

    it 'redirects to context group permissions path' do
      expect(response).to redirect_to(
        context_context_group_permissions_url(context))
      expect(flash[:success]).to eq(
        'The Context Group Permission has been updated.')
    end
  end

  describe '#destroy' do
    it 'deletes the permission' do
      permission = create(:context_group_permission, context: context)

      expect do
        delete(:destroy,
               params: {
                 context_id: context.id,
                 id: permission.id
               },
               session: { user_id: admin_user.id })
      end.to change { Permissions::ContextGroupPermission.count }.by(-1)
    end
  end
end
