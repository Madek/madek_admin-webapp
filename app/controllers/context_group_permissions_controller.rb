class ContextGroupPermissionsController < ApplicationController
  include ContextPermissions
  define_actions_for :group_permissions

  def index
    @group_permissions = @context.group_permissions.includes(:group)
  end

  def new
    @permission = Permissions::ContextGroupPermission.new
    @permission.group_id = params[:group_id]
  end

  def destroy
    @context.group_permissions.destroy(params[:id])

    redirect_to context_context_group_permissions_path,
                flash: {
                  success: 'The Context Group Permission has been deleted.' }
  end

  private

  def permission_params
    params.require(:context_group_permission).permit(:group_id,
                                                      :use,
                                                      :view)
  end
end
