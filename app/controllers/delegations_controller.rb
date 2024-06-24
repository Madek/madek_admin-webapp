class DelegationsController < ApplicationController
  def index
    @delegations = Delegation
      .all
      .with_members_count
      .with_resources_count
      .filter_by(params[:search_term], params[:group_or_user_id])
      .apply_sorting(params[:sort_by])
      .page(page_params)
  end

  def new
    @delegation = Delegation.new(new_delegation_params)
  end

  def create
    if new_action_type_param == 'add_supervisor'
      redirect_to users_path(
        as_supervisor: true,
        return_to: new_delegation_path(delegation: new_delegation_params)
      )
    else
      delegation = Delegation.create!(new_delegation_params)
      respond_with delegation
    end
  end

  def edit
    @delegation = find_delegation
  end

  def update
    delegation = find_delegation
    delegation.update!(delegation_params)

    respond_with delegation
  end

  def destroy
    delegation = find_delegation
    delegation.destroy!

    respond_with delegation
  end

  def show
    @delegation = find_delegation
    users = @delegation.users.page(params[:users_page])
    if (search_term = params.fetch(:users, {})[:search_term]).present?
      users = users.filter_by(search_term, false, true)
    end
    supervisors = @delegation.supervisors.page(params[:supervisors_page])
    if (search_term = params.fetch(:supervisors, {})[:search_term]).present?
      supervisors = supervisors.filter_by(search_term, false, true)
    end
    groups = @delegation.groups.page(params[:groups_page])
    if (search_term = params.fetch(:groups, {})[:search_term]).present?
      groups = groups.filter_by(search_term, false, true)
    end
    @members = {
      users: {
        attributes: %w(login email id),
        collection: users
      },
      groups: {
        attributes: %w(name id),
        collection: groups
      },
      supervisors: {
        attributes: %w(login email id),
        collection: supervisors
      }
    }
  end

  def form_add_user
    redirect_to users_path(add_to_delegation_id: find_delegation.id)
  end

  def add_user
    delegation = find_delegation
    delegation.users << User.find(params[:user_id])

    respond_with delegation, notice: 'The user has been added.'
  end

  def form_add_supervisor
    redirect_to users_path(add_to_delegation_id: find_delegation.id,
                           as_supervisor: true)
  end

  def add_supervisor
    delegation = find_delegation
    delegation.supervisors =
      delegation.supervisors + [User.find(params[:user_id])]

    respond_with delegation, notice: 'The supervisor has been added.'
  end

  def form_add_group
    redirect_to groups_path(add_to_delegation_id: find_delegation.id)
  end

  def add_group
    delegation = find_delegation
    delegation.groups << Group.find(params[:group_id])

    respond_with delegation, notice: 'The group has been added.'
  end

  private

  def new_delegation_params
    params.fetch(:delegation, {})
      .permit(:name,
              :description,
              :admin_comment,
              :notifications_email,
              :notify_all_members,
              :supervisor_ids => [])
      .transform_values { |v| v.presence }
  end

  def delegation_params
    params.require(:delegation)
      .permit(:name,
              :description,
              :admin_comment,
              :notifications_email,
              :notify_all_members)
      .transform_values { |v| v.presence }
  end

  def new_action_type_param
    params.fetch(:button)
  end

  def find_delegation
    Delegation.find(params[:id])
  end
end
