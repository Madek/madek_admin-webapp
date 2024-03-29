require 'spec_helper'

describe GroupsController do
  let(:admin_user) { create :admin_user }

  describe '#index' do
    it 'responds with status code 200' do
      get :index, session: { user_id: admin_user.id }

      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    describe 'filtering/sorting groups' do
      context 'by type' do
        it "returns groups with 'Group' type" do
          get(
            :index,
            params: { type: 'Group' },
            session: { user_id: admin_user.id })

          expect(assigns(:groups)) \
            .to match_array(Group.page(1).per(25).where(type: 'Group'))
        end

        it "returns groups with 'InstitutionalGroup' type" do
          get(
            :index,
            params: { type: 'InstitutionalGroup' },
            session: { user_id: admin_user.id })

          expect(assigns(:groups)).to match_array(Group.page(1).per(25) \
            .where(type: 'InstitutionalGroup'))
        end

      end

      context 'by name' do
        it "returns groups with 'test_foo' in their name" do
          group1 = create :group, name: 'test_foo1'
          group2 = create :group, name: 'test_foo2'
          group3 = create :group, name: 'test_foo3'

          get(
            :index,
            params: { search_terms: 'test_foo', sort_by: 'name' },
            session: { user_id: admin_user.id }
          )

          expect(assigns(:groups)).to match_array [group1, group2, group3]
        end
      end

      context 'by text search ranking' do
        it "returns groups found by text search ranking with 'test'" do
          group1 = create :group, name: 'test one'
          group2 = create :group, name: 'test two'
          group3 = create :group, name: 'test three'

          get(
            :index,
            params: { search_terms: 'test', sort_by: 'text_rank' },
            session: { user_id: admin_user.id }
          )

          expect(assigns(:groups)).to match_array [group1, group2, group3]
        end

        it 'returns error when search_terms are missing' do
          get(
            :index,
            params: { search_terms: '', sort_by: 'text_rank' },
            session: { user_id: admin_user.id }
          )
          expect(flash[:error]).to eq 'Search term must not be blank!'
        end
      end

      context 'by trigram search ranking' do
        it "returns groups found by trigram search ranking with 'test'" do
          group1 = create :group, name: 'foo1'
          group2 = create :group, institutional_name: 'foo2'
          group3 = create :group, name: 'foo3'

          get(
            :index,
            params: { search_terms: 'foo', sort_by: 'trgm_rank', type: 'Group' },
            session: { user_id: admin_user.id }
          )

          expect(assigns(:groups)).to match_array [group1, group2, group3]
        end

        it 'returns error when search_terms are missing' do
          get(
            :index,
            params: { search_terms: '', sort_by: 'trgm_rank' },
            session: { user_id: admin_user.id }
          )
          expect(flash[:error]).to eq 'Search term must not be blank!'
        end
      end
    end
  end

  describe '#show' do
    let!(:group) { create :group }
    let(:session) { { user_id: admin_user.id } }

    it 'responds with status code 200' do
      get :show, params: { id: group.id }, session: session
      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    it 'renders the show template' do
      get :show, params: { id: group.id }, session: session
      expect(response).to render_template(:show)
    end

    it 'loads the proper group into @group' do
      get :show, params: { id: group.id }, session: session
      expect(assigns[:group]).to eq group
    end

    context 'when previous id was passed' do
      it 'redirects to current group page' do
        previous_obj = create(:group)
        current_obj = create(:group)

        previous_obj.merge_to(current_obj)

        get(:show, params: { id: previous_obj.id }, session: session)

        expect(response).to redirect_to(group_path(current_obj))
      end
    end

    context 'when not existing id was passed' do
      render_views
      let(:fake_id) { SecureRandom.uuid }

      it 'raises 404 error' do
        get(:show, params: { id: fake_id }, session: session)

        expect(response).to have_http_status :not_found
      end

      it 'includes the id in response body' do
        get(:show, params: { id: fake_id }, session: session)

        expect(response.body).to include(fake_id)
      end
    end
  end

  describe '#new' do
    it 'renders template' do
      get :new, session: { user_id: admin_user.id }

      expect(response).to render_template :new
    end
  end

  describe '#update' do
    context 'Group' do
      let!(:group) { create :group }

      it 'redirects to group#show after successful update' do
        patch(
          :update,
          params: { id: group.id, group: { name: 'NEW NAME' } },
          session: { user_id: admin_user.id }
        )

        expect(response).to have_http_status(302)
        expect(response).to redirect_to group_path(assigns(:instance))
      end

      it 'updates the group' do
        patch(
          :update,
          params: { id: group.id, group: { name: 'NEW NAME' } },
          session: { user_id: admin_user.id }
        )

        expect(flash[:success]).to eq flash_message(:update, :success)
        expect(group.reload.name).to eq 'NEW NAME'
      end

      context 'failed validations' do
        it 'displays error messages and redirects' do
          patch(
            :update,
            params: { id: group.id, group: { name: '' } },
            session: { user_id: admin_user.id }
          )

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template 'errors/422'
        end
      end
    end

    context 'InstitutionalGroup' do
      let!(:group) { create :institutional_group }

      it 'redirects to group#show after successful update' do
        patch(
          :update,
          params: { id: group.id, group: { name: 'NEW NAME' } },
          session: { user_id: admin_user.id }
        )

        expect(response).to have_http_status(302)
        expect(response).to redirect_to group_path(assigns(:instance))
      end

      it 'updates the group' do
        patch(
          :update,
          params: { id: group.id, group: { name: 'NEW NAME' } },
          session: { user_id: admin_user.id }
        )

        expect(flash[:success]).to eq(
          flash_message(:update, :success, 'Institutional group')
        )
        expect(group.reload.name).to eq 'NEW NAME'
      end
    end

    context 'AuthenticationGroup' do
      let!(:group) { create :authentication_group }

      before do
        patch(
          :update,
          params: { id: group.id, group: { name: 'NEW NAME' } },
          session: { user_id: admin_user.id }
        )
      end

      it 'redirects to group#show after successful update' do
        expect(response).to have_http_status(302)
        expect(response).to redirect_to group_path(assigns(:instance))
      end

      it 'updates the group' do
        expect(flash[:success]).to eq(
          flash_message(:update, :success, 'Authentication group')
        )
        expect(group.reload.name).to eq 'NEW NAME'
      end
    end
  end

  describe '#create' do
    it 'redirects to group#show after successful create' do
      post(
        :create,
        params: { group: attributes_for(:group) },
        session: { user_id: admin_user.id })

      expect(response).to redirect_to group_path(assigns(:group))
      expect(flash[:success]).to eq flash_message(:create, :success)
    end

    it 'creates a group' do
      expect do
        post(
          :create,
          params: { group: attributes_for(:group) },
          session: { user_id: admin_user.id })
      end.to change { Group.count }.by(1)
    end

    context 'failed validation' do
      it 'renders error template' do
        post(
          :create,
          params: { group: { name: '' } },
          session: { user_id: admin_user.id })

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template 'errors/422'
      end
    end
  end

  describe '#destroy' do
    context 'Group' do
      let!(:group) { create :group }

      context 'when group does not have any users' do
        it 'redirects to admin groups path after a successful destroy' do
          delete(
            :destroy,
            params: { id: group.id },
            session: { user_id: admin_user.id })

          expect(response).to redirect_to(groups_path)
          expect(flash[:success]).to eq flash_message(:destroy, :success)
        end

        it 'destroys the group' do
          expect do
            delete(
              :destroy,
              params: { id: group.id },
              session: { user_id: admin_user.id })
          end.to change { Group.count }.by(-1)
        end
      end

      context 'when group has some users' do
        before { group.users << [create(:user), create(:user)] }

        it 'redirects to a correct path depending on referrer param' do
          delete(
            :destroy,
            params: { id: group.id, redirect_path: group_path(group) },
            session: { user_id: admin_user.id }
          )

          expect(response).to have_http_status(302)
          expect(response).to redirect_to group_path(group)
        end
      end
    end

    context 'InstitutionalGroup' do
      let!(:group) { create :institutional_group }

      context 'when group does not have any users' do
        it 'redirects to admin groups path after a successful destroy' do
          delete(
            :destroy,
            params: { id: group.id },
            session: { user_id: admin_user.id })

          expect(response).to redirect_to(groups_path)
          expect(flash[:success]).to eq(
            flash_message(:destroy, :success, 'Institutional group')
          )
        end

        it 'destroys the group' do
          expect do
            delete(
              :destroy,
              params: { id: group.id },
              session: { user_id: admin_user.id })
          end.to change { Group.count }.by(-1)
        end
      end

      context 'when group has some users' do
        before { group.users << [create(:user), create(:user)] }

        it 'redirects to a correct path depending on referrer param' do
          delete(
            :destroy,
            params: { id: group.id, redirect_path: group_path(group) },
            session: { user_id: admin_user.id }
          )

          expect(response).to have_http_status(302)
          expect(response).to redirect_to group_path(group)
        end
      end
    end

    context 'AuthenticationGroup' do
      let!(:group) { create :authentication_group }

      it 'renders forbidden message' do
        delete(
          :destroy,
          params: { id: group.id },
          session: { user_id: admin_user.id })

        expect(response).to have_http_status :forbidden
      end
    end
  end

  describe '#form_add_user' do
    let(:group) { create :group }

    it 'redirects to users listing with proper url param' do
      get(
        :form_add_user,
        params: { id: group.id },
        session: { user_id: admin_user.id })

      expect(response).to have_http_status 302
      expect(response).to redirect_to users_path(add_to_group_id: group.id)
    end
  end

  describe '#add_user' do
    let!(:group) { create :group }
    let!(:user)  { create :user  }

    it 'redirects to group page after successful addition' do
      post(
        :add_user,
        params: { id: group.id, user_id: user.id },
        session: { user_id: admin_user.id })

      expect(response).to redirect_to(group_path(group))
      expect(flash[:success]).to eq(
        "The user <strong>#{user.login}</strong> has been added.")
    end

    it 'adds user to selected group' do
      expect do
        post(
          :add_user,
          params: { id: group.id, user_id: user.id },
          session: { user_id: admin_user.id })
      end.to change { group.users.count }.by(1)
    end

    it 'displays an error if user is already a member' do
      post(
        :add_user,
        params: { id: group.id, user_id: user.id },
        session: { user_id: admin_user.id })
      post(
        :add_user,
        params: { id: group.id, user_id: user.id },
        session: { user_id: admin_user.id })
      expect(response).to redirect_to(group_path(group))
      expect(flash[:error]).to eq(
        "The user <strong>#{user.login}</strong> already belongs to this group.")
    end

    it 'displays error template if something goes wrong' do
      post(
        :add_user,
        params: { id: group.id, user_id: '' },
        session: { user_id: admin_user.id })

      expect(response).to have_http_status(404)
      expect(response).to render_template 'errors/404'
    end

    context 'AuthenticationGroup' do
      let!(:group) { create :authentication_group }

      it 'renders forbidden message' do
        post(
          :add_user,
          params: { id: group.id, user_id: user.id },
          session: { user_id: admin_user.id })

        expect(response).to have_http_status :forbidden
      end
    end
  end

  describe '#form_merge_to' do
    let(:group) { create :institutional_group }

    it 'renders template' do
      get(
        :form_merge_to,
        params: { id: group.id },
        session: { user_id: admin_user.id })

      expect(response).to be_successful
      expect(response).to render_template :form_merge_to
    end
  end

  describe '#merge_to' do
    let!(:department1) do
      dep = build :group, type: 'InstitutionalGroup'
      dep.save(validate: false)
      dep
    end
    let!(:department2) do
      dep = build :group, type: 'InstitutionalGroup'
      dep.save(validate: false)
      dep
    end
    let!(:group) { create :group }

    it 'merges two institutional groups' do
      post(
        :merge_to,
        params: { id: department1.id, id_receiver: department2.id },
        session: { user_id: admin_user.id }
      )
      expect(response).to redirect_to(group_path(department2))
      expect(flash[:success]).to eq 'The group has been merged.'
    end

    it "displays error template if target group isn't institutional group" do
      post(
        :merge_to,
        params: { id: department1.id, id_receiver: group.id },
        session: { user_id: admin_user.id }
      )

      expect(response).to have_http_status(:not_found)
      expect(response).to render_template 'errors/404'
    end
  end

  def flash_message(action, type, resource_name = 'Group')
    I18n.t type, scope: "flash.actions.#{action}", resource_name: resource_name
  end
end
