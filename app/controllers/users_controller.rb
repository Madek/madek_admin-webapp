class UsersController < ApplicationController
  before_action :find_user, except: [
    :index, :new, :new_with_person, :create, :remove_user_from_group, :remove_from_delegation
  ]
  before_action :initialize_user, only: [:new, :new_with_person]

  def index
    @users = filter(User)
    @users = @users.order_by(params[:sort_by]) if params[:sort_by].present?
    @users = @users.page(page_params).per(16)
    @return_to = return_to_param

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

    if new_password = user_params[:password].presence
      @user.password = new_password
      @user.save_new_password
    end

    @user.update!(user_params)

    respond_with @user, location: -> { user_path(@user) }
  end

  def create
    @user = User.new(user_params)

    if @user.person_id.nil?
      @user.person = Person.new(subtype: 'Person', first_name: @user.first_name, last_name: @user.last_name)
    end

    @user.save!

    respond_with @user, location: -> { users_path }
  end

  def destroy
    @user.destroy!

    respond_with @user, location: -> { users_path }
  rescue => e
    @model_error_messages = @user.errors.map(&:full_message)
    @extra_error_message = [
      'The user cannot be deleted. However you can mark it as deactivated.',
      view_context.link_to('Click here to do that', edit_user_path(@user))
    ].join(' ')
    render_error(e) and return
  end

  def switch_to
    unless @user.activated?
      raise Errors::ForbiddenError, 'Target user is deactivated.'
    end

    auth_system = @session.auth_system
    reset_session
    destroy_madek_session
    set_madek_session(@user, auth_system)
    redirect_to '/my'

  rescue => e
    render_error(e)
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

    if group.users.empty?
      respond_with group,
                  location: -> { groups_path() },
                  notice: 'The user has been removed. The group was deleted because it was empty.'
    else
      respond_with group,
                  location: -> { group_path(group) },
                  notice: 'The user has been removed.'
    end
  end

  def remove_from_delegation
    delegation = Delegation.find(params[:delegation_id])
    user = User.find(params[:user_id])

    if as_supervisor_param
      delegation.supervisors.delete(user)
    else
      delegation.users.delete(user)
    end

    respond_with(
      delegation,
      notice: "The #{as_supervisor_param ? 'supervisor' : 'user'} has been removed."
    )
  end

  private

  def initialize_user
    @user = User.new
  end

  def find_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit!
  end

  def as_supervisor_param
    params.fetch(:as_supervisor, nil) == 'true'
  end

  def return_to_param
    params.fetch(:return_to, nil)
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
    @delegation_supervisor_ids = []
    if as_supervisor_param
      if @return_to
        uri = URI.parse(@return_to)
        query_params = 
          Rack::Utils
          .parse_nested_query(uri.query)
          .with_indifferent_access
        @uri_spec = { path: uri.path, query_params: query_params }
      end

      @as_supervisor = true
      supervisor_ids = @delegation.try(:supervisor_ids) || query_params[:delegation][:supervisor_ids]
      if supervisor_ids.present?
        @delegation_supervisor_ids = supervisor_ids
      end
    end
    @delegation_name =
      @delegation.try(:name) ||
      query_params.try(:[], :delegation).try(:[], :name)
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
