require 'spec_helper'

describe UsersController do
  let!(:admin_user) { create :admin_user }

  describe '#index' do
    it 'responds with HTTP 200 status code' do
      get :index, session: { user_id: admin_user.id }

      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    it 'loads the first page of users into @users' do
      get :index, session: { user_id: admin_user.id }

      expect(response).to be_successful
      expect(assigns(:users)).to eq User.first(16)
    end

    it 'remembers in session ids of values related to permission' do
      get(:index,
          params: { permission_id: 123, vocabulary_id: 321 },
          session: { user_id: admin_user.id })

      expect(session[:permission_id]).to eq '123'
      expect(session[:vocabulary_id]).to eq '321'
    end

    describe 'filtering users' do
      context 'by login' do
        it "returns users containing 'xxx' in login" do
          user_1 = create :user, login: 'adam1xxx'
          user_2 = create :user, login: 'adam2xxx'
          user_3 = create :user, login: 'adxxxam3'

          get(
            :index,
            params: { search_term: 'xxx' },
            session: { user_id: admin_user.id })

          expect(response).to be_successful
          expect(assigns(:users)).to eq [user_1, user_2, user_3]
        end
      end

      context 'by email' do
        it "returns users containing 'xxx' in email" do
          user_1 = create :user, email: 'adamxxx@madek.zhdk.ch'
          user_2 = create :user, email: 'adam@madekxxx.zhdk.ch'
          user_3 = create :user, email: 'adxxxam@madek.zhdk.ch'

          get(
            :index,
            params: { search_term: 'xxx' },
            session: { user_id: admin_user.id })

          expect(response).to be_successful
          expect(assigns(:users)).to match_array [user_1, user_2, user_3]
        end
      end

      context 'by admin role' do
        it 'returns only admin users' do
          get :index, params: { admins: 1 }, session: { user_id: admin_user.id }

          expect(response).to be_successful
          expect(assigns(:users)).to match_array User.admins
        end
      end

      context 'by deactivated status' do
        it 'returns only deactivated users' do
          deactivated_user = create(:user, :deactivated)

          get(
            :index,
            params: { deactivated: 1 },
            session: { user_id: admin_user.id })

          expect(assigns(:users)).to eq [deactivated_user]
        end
      end
    end

    describe 'sorting users' do
      context 'by login (default)' do
        it 'returns users sorted by login in ascending order' do
          get :index, session: { user_id: admin_user.id }

          expect(response).to be_successful
          expect(assigns[:users]).to eq User.page(1).per(16)
        end
      end

      context 'by email address' do
        it 'returns users sorted by email in ascending order' do
          get(
            :index,
            params: { sort_by: :email },
            session: { user_id: admin_user.id })

          expect(response).to be_successful
          expect(assigns[:users].pluck(:email)).to eq(
            assigns[:users].pluck(:email).sort)
        end
      end

      context 'by person first name and last name' do
        it 'returns users with a correct order' do
          get(
            :index,
            params: { sort_by: :first_name_last_name },
            session: { user_id: admin_user.id })

          expect(response).to be_successful
          expect(full_names(assigns[:users])).to eq(
            full_names(assigns[:users]).sort)
        end
      end

      def full_names(users)
        users.to_a.map(&:person).map(&:to_s)
      end
    end
  end

  describe '#show' do
    let(:user) { create :user }

    it 'responds with HTTP 200 status code' do
      get :show, params: { id: user.id }, session: { user_id: admin_user.id }

      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    it 'renders the show template' do
      get :show, params: { id: user.id }, session: { user_id: admin_user.id }

      expect(response).to render_template(:show)
    end

    it 'loads the proper user into @user' do
      get :show, params: { id: user.id }, session: { user_id: admin_user.id }

      expect(assigns[:user]).to eq user
    end
  end

  describe '#switch_to' do
    let(:user) { create :user }

    it 'redirects to the /my path' do
      post(
        :switch_to,
        params: { id: user.id },
        session: { user_id: admin_user.id })

      expect(response).to redirect_to('/my')
      expect(response).to have_http_status(302)
    end

  end

  describe '#reset_usage_terms' do
    let(:usage_terms) { create(:usage_terms) }
    let(:user) { create :user, accepted_usage_terms: usage_terms }

    it 'redirects to admin users path' do
      patch(
        :reset_usage_terms,
        params: { id: user.id },
        session: { user_id: admin_user.id })

      expect(response).to redirect_to(users_path)
      expect(response).to have_http_status(302)
      expect(flash[:success]).to eq 'The usage terms have been reset.'
    end

    it 'resets usage terms for the user' do
      expect(user.accepted_usage_terms_id).to eq usage_terms.id

      patch(
        :reset_usage_terms,
        params: { id: user.id },
        session: { user_id: admin_user.id })

      expect(user.reload.accepted_usage_terms_id).to be_nil
    end
  end

  describe '#grant_admin_role' do
    let(:user) { create :user }

    it 'redirects to the given redirect path' do
      patch(
        :grant_admin_role,
        params: { id: user.id, redirect_path: user_path(user) },
        session: { user_id: admin_user.id }
      )

      expect(response).to redirect_to(user_path(user))
      expect(response).to have_http_status(302)
      expect(flash[:success]).to eq(
        'The admin role has been granted to the user.')
    end

    it 'grants the admin role to the user' do
      patch(
        :grant_admin_role,
        params: { id: user.id, redirect_path: users_path },
        session: { user_id: admin_user.id }
      )

      expect(user.reload).to be_admin
    end

    context 'when some error occured during action' do
      it 'renders error template' do
        allow(Admin).to receive(:create!).and_raise(ActiveRecord::RecordNotFound)

        patch(
          :grant_admin_role,
          params: { id: user.id, redirect_path: user_path(user) },
          session: { user_id: admin_user.id }
        )

        expect(response).to have_http_status(:not_found)
        expect(response).to render_template 'errors/404'
      end
    end
  end

  describe '#remove_admin_role' do
    let(:user) { create :admin_user }

    it 'redirects to the given redirect path' do
      delete(
        :remove_admin_role,
        params: { id: user.id, redirect_path: users_path },
        session: { user_id: admin_user.id }
      )

      expect(response).to redirect_to(users_path)
      expect(response).to have_http_status(302)
      expect(flash[:success]).to eq(
        'The admin role has been removed from the user.')
    end

    it 'removes the admin role from the user' do
      delete(
        :remove_admin_role,
        params: { id: user.id, redirect_path: user_path(user) },
        session: { user_id: admin_user.id }
      )

      expect(user.reload).not_to be_admin
    end
  end

  describe '#edit' do
    let(:user) { create :user }

    it 'responds with HTTP 200 status code' do
      get :edit, params: { id: user.id }, session: { user_id: admin_user.id }

      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    it 'render the edit template and assigns the user to @user' do
      get :edit, params: { id: user.id }, session: { user_id: admin_user.id }

      expect(response).to render_template(:edit)
      expect(assigns[:user]).to eq user
    end
  end

  describe '#update' do
    let(:user) { create :user }

    it 'redirects to admin user show page' do
      patch(
        :update,
        params: { id: user.id, user: { login: 'george' } },
        session: { user_id: admin_user.id }
      )

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(user_path(user))
    end

    it 'updates the user' do
      patch(
        :update,
        params: { id: user.id, user: { login: 'george' } },
        session: { user_id: admin_user.id }
      )

      expect(flash[:success]).to eq flash_message(:update, :success)
      expect(user.reload.login).to eq 'george'
    end

    it 'renders error template when something went wrong' do
      patch(
        :update,
        params: { id: UUIDTools::UUID.random_create },
        session: { user_id: admin_user.id })

      expect(response).to have_http_status(:not_found)
      expect(response).to render_template 'errors/404'
    end
  end

  describe '#create' do
    context 'without person' do
      it 'redirects to admin users path after successfuly created user' do
        post(
          :create,
          params: { user: user_params },
          session: { user_id: admin_user.id })

        expect(response).to have_http_status(302)
        expect(response).to redirect_to(users_path)
        expect(flash[:success]).to eq flash_message(:create, :success)
      end

      it 'creates an user' do
        expect do
          post(
            :create,
            params: { user: user_params },
            session: { user_id: admin_user.id })
        end.to change { User.count }.by(1)
      end

      context 'when validation failed' do
        it 'renders error template' do
          post(
            :create,
            params: { user: { email: '' } },
            session: { user_id: admin_user.id })

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template 'errors/422'
        end
      end

      def user_params
        {
          login: Faker::Internet.user_name,
          email: Faker::Internet.email,
          password: Faker::Internet.password,
          person_id: create(:person).id
        }
      end
    end

    context 'with person' do
      it 'redirects to admin users path after successfuly created user' do
        post(
          :create,
          params: { user: user_params },
          session: { user_id: admin_user.id })

        expect(response).to have_http_status(302)
        expect(response).to redirect_to(users_path)
        expect(flash[:success]).to eq flash_message(:create, :success)
      end

      it 'creates an user' do
        expect do
          post(
            :create,
            params: { user: user_params },
            session: { user_id: admin_user.id })
        end.to change { User.count }.by(1)
      end

      context 'when validation failed' do
        it 'renders error template' do
          attributes = {
            login: 'example-login',
            email: 'nickname at example.com', # <-- invalid
            first_name: 'Nick',
            last_name: 'Name'
          }
          post(
            :create,
            params: { user: attributes },
            session: { user_id: admin_user.id })

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template 'errors/422'
        end
      end

      def user_params
        {
          login: Faker::Internet.user_name,
          email: Faker::Internet.email,
          password: Faker::Internet.password,
          first_name: Faker::Name.first_name,
          last_name: Faker::Name.last_name
        }
      end
    end
  end

  describe '#destroy' do
    let!(:user) { create :user }

    it 'redirects to admin users path after succesful destroy' do
      delete(
        :destroy,
        params: { id: user.id },
        session: { user_id: admin_user.id })

      expect(response).to redirect_to(users_path)
      expect(flash[:success]).to eq flash_message(:destroy, :success)
    end

    it 'destroys the user' do
      expect do
        delete(
          :destroy,
          params: { id: user.id },
          session: { user_id: admin_user.id })
      end.to change { User.count }.by(-1)
    end

    context 'when user cannot be deleted because of foreign key constraints' do
      let!(:collection) { create(:collection, creator_id: user.id) }

      it 'renders error template with extra message' do
        delete :destroy,
               params: { id: user.id },
               session: { user_id: admin_user.id }

        expect(response).to have_http_status 500
        expect(response).to render_template 'errors/500'
        expect(assigns[:extra_error_message]).to be_present
      end
    end
  end

  describe '#remove_user_from_group' do
    context 'Group' do
      let!(:group) { create :group }
      let!(:user) { create :user }

      it 'removes user from the group' do
        group.users << user

        expect(group.users).to include user

        delete(
          :remove_user_from_group,
          params: { group_id: group.id, user_id: user.id },
          session: { user_id: admin_user.id }
        )

        expect(response).to have_http_status 302
        expect(response).to redirect_to groups_path()
        expect(group.users.reload).not_to include user
      end
    end

    context 'InstitutionalGroup' do
      let!(:group) { create :institutional_group }
      let!(:user) { create :user }

      it 'removes user from the group' do
        group.users << user

        expect(group.users).to include user

        delete(
          :remove_user_from_group,
          params: { group_id: group.id, user_id: user.id },
          session: { user_id: admin_user.id }
        )

        expect(response).to have_http_status 302
        expect(response).to redirect_to groups_path()
        expect(group.users.reload).not_to include user
      end
    end

    context 'AuthenticationGroup' do
      let!(:group) { create :authentication_group }
      let!(:user) { create :user }

      it 'render forbidden message' do
        group.users << user

        expect(group.users).to include user

        delete(
          :remove_user_from_group,
          params: { group_id: group.id, user_id: user.id },
          session: { user_id: admin_user.id }
        )

        expect(response).to have_http_status :forbidden
        expect(response.body).to end_with 'Access denied!'
        expect(group.users.reload).to include user
      end
    end
  end

  def flash_message(action, type)
    I18n.t type, scope: "flash.actions.#{action}", resource_name: 'User'
  end
end
