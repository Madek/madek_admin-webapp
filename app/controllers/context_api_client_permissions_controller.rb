class ContextApiClientPermissionsController < ApplicationController
  include ContextPermissions
  define_actions_for :api_client_permissions

  def index
    @api_client_permissions =
      @context.api_client_permissions.includes(:api_client)
  end

  def new
    @permission =
      Permissions::ContextApiClientPermission.new
    @permission.api_client_id = params[:api_client_id]
  end

  def destroy
    @context.api_client_permissions.destroy(params[:id])

    redirect_to(
      context_context_api_client_permissions_path,
      flash: {
        success: 'The Context API Client Permission has been deleted.' }
    )
  end

  private

  def permission_params
    params.require(:context_api_client_permission).permit(:api_client_id,
                                                           :use,
                                                           :view)
  end
end
