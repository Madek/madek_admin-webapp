class ContextUserPermissionsController < ApplicationController
  include ContextPermissions
  define_actions_for :user_permissions

  def index
    @user_permissions = @context.user_permissions.includes(:user)
  end

  def new
    @permission = Permissions::ContextUserPermission.new
    @permission.user_id = params[:user_id]
  end

  def destroy
    @context.user_permissions.destroy(params[:id])

    redirect_to context_context_user_permissions_path,
                flash: {
                  success: 'The Context User Permission has been deleted.' }
  end

  private

  def permission_params
    params.require(:context_user_permission).permit(:user_id,
                                                     :use,
                                                     :view)
  end
end
