require 'csv'

class RolesController < ApplicationController
  def index
    @roles = Role
               .filter_by(filter_value(:term, nil))
               .sorted
               .page(page_params)
               .per(16)

    @roles_list = if params[:add_to_roles_list_id].present?
                    RolesList.find(params[:add_to_roles_list_id])
                  end
  end

  def new
    @role = Role.new
  end

  def create
    role = Role.new(role_params)
    role.creator = current_user
    role.save!
    respond_with role, location: roles_path
  end

  def edit
    @role = Role.find(params[:id])
  end

  def update
    role = Role.find(params[:id])
    role.update!(role_params)
    respond_with role, location: roles_path
  end

  def destroy
    role = Role.find(params[:id])
    role.destroy!
    respond_with role, location: roles_path
  end

  def remove_from_roles_list
    roles_list = RolesList.find(params[:roles_list_id])
    roles_list.roles.delete(Role.find(params[:role_id]))

    respond_with roles_list, notice: 'The role has been removed.'
  end

  private

  def role_params
    params.require(:role).permit!
  end

end
