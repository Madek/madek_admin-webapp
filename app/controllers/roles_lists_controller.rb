class RolesListsController < ApplicationController
  def index
    @roles_lists = RolesList
      .filter_by(filter_value(:term, nil))
      .sorted
      .page(page_params)
      .per(16)
  end

  def new
    @roles_list = RolesList.new
  end

  def show
    @roles_list = RolesList.find(params[:id])
    @roles = @roles_list.roles
  end

  def create
    roles_list = RolesList.new(roles_list_params)
    roles_list.save!
    respond_with roles_list, location: roles_lists_path
  end

  def edit
    @roles_list = RolesList.find(params[:id])
  end

  def update
    roles_list = RolesList.find(params[:id])
    roles_list.update!(roles_list_params)
    respond_with roles_list, location: roles_lists_path
  end

  def destroy
    roles_list = RolesList.find(params[:id])
    roles_list.destroy!
    respond_with roles_list, location: roles_lists_path
  end

  def add_role
    @roles_list = RolesList.find(params[:id])
    @role = Role.find(params[:role_id])
    if @roles_list.roles.include?(@role)
      flash = { error: "The Role <strong>#{@role.label}</strong> " \
                       'already belongs to this Roles List.'.html_safe }
    else
      @roles_list.roles << @role
      flash = { success: "The Role <strong>#{@role.label}</strong> " \
                         'has been added.'.html_safe }
    end

    redirect_to roles_list_path(@roles_list), flash: flash
  end

  private

  def roles_list_params
    params.require(:roles_list).permit!
  end

end
