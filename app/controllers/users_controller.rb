class UsersController < ApplicationController
  before_action :find_user, except: [
    :index, :new, :new_with_person, :create, :remove_user_from_group, :remove_from_delegation
  ]
  before_action :initialize_user, only: [:new, :new_with_person]

  def index
    @users = filter(User)
    @users = @users.order_by(params[:sort_by]) if params[:sort_by].present?
    @users = @users.page(page_params).per(16)

    remember_vocabulary_url_params
    get_api_client_params
    get_group_from_params
    get_delegation_from_params
  end

  def reset_usage_terms
    @user.reset_usage_terms

    respond_with @user,
                 location: -> { users_path },
                 notice: 'The usage terms have been reset.'
  end

  def show
  end

  def edit
  end

  def new
  end

  def new_with_person
    @user.build_person
  end

  def update
    @user.update!(user_params)

    respond_with @user, location: -> { user_path(@user) }
  end

  def create
    @user = User.new(user_params)
    @user.save!

    respond_with @user, location: -> { users_path }
  end

  def destroy
    @user.destroy!

    respond_with @user, location: -> { users_path }
  rescue => e
    @extra_error_message = [
      'The user cannot be deleted. However you can mark it as deactivated.',
      view_context.link_to('Click here to do that', edit_user_path(@user))
    ].join(' ')
    render_error(e) and return
  end

  def switch_to
    reset_session
    destroy_madek_session
    set_madek_session(@user)
    redirect_to '/my'
  end

  def grant_admin_role
    Admin.create!(user: @user)

    respond_with @user,
                 location: -> { params[:redirect_path] },
                 notice: 'The admin role has been granted to the user.'
  end

  def remove_admin_role
    Admin.find_by(user_id: @user.id).destroy!

    respond_with @user,
                 location: -> { params[:redirect_path] },
                 notice: 'The admin role has been removed from the user.'
  end

  def remove_user_from_group
    group = Group.find params[:group_id]
    authorize group
    group.users.delete(User.find(params[:user_id]))

    respond_with group,
                 location: -> { group_path(group) },
                 notice: 'The user has been removed.'
  end

  def remove_from_delegation
    delegation = Delegation.find(params[:delegation_id])
    delegation.users.delete(User.find(params[:user_id]))

    respond_with delegation, notice: 'The user has been removed.'
  end

  private

  def initialize_user
    @user = User.new
  end

  def find_user
    @user = User.find(params[:id])
  end

  def person_attributes?
    params[:user][:person_attributes] rescue false
  end

  def user_params
    params.require(:user).permit!
  end

  def get_api_client_params
    @api_client_params = params[(
      %i(new_api_client edited_api_client).detect do |group|
        params[group].present?
      end
    )]&.permit(:id, :login, :description)
  end

  def get_group_from_params
    @group = Group.find_by(id: params[:add_to_group_id])
  end

  def get_delegation_from_params
    @delegation = Delegation.find_by(id: params[:add_to_delegation_id])
    @delegation_user_ids = @delegation&.user_ids || []
  end

  def filter(relation)
    if params[:search_term].present?
      relation = relation.filter_by(params[:search_term], false, true)
    end
    [:admins, :deactivated].each do |filter_scope|
      relation = relation.send(filter_scope) if params[filter_scope] == '1'
    end
    relation
  end
end
