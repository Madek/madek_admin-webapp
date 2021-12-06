class ContextApiClientPermissionsController < ApplicationController
  before_action :set_context

  def index
    @api_client_permissions = @context.api_client_permissions.includes(:api_client)
  end

  def new
    @permission = Permissions::ContextApiClientPermission.new(context: @context)
    if (@api_client = ApiClient.find_by(id: params[:api_client_id]))
      @permission.api_client = @api_client
    end
  end

  def create
    permission = @context.api_client_permissions.create!(permission_params)

    respond_with permission,
                 location: -> { context_context_api_client_permissions_path(@context) },
                 notice: 'The API Client Permission has been created.'
  end

  def edit
    @permission = @context.api_client_permissions.find(params[:id])
    if (updated_api_client = ApiClient.find_by(id: params[:api_client_id]))
      @permission.api_client = updated_api_client
    end
  end

  def update
    permission = @context.api_client_permissions.find(params[:id])
    permission.update!(permission_params)

    respond_with permission,
                 location: -> { context_context_api_client_permissions_path(@context) },
                 notice: 'The API Client Permission has been updated.'
  end

  def destroy
    permission = @context.api_client_permissions.destroy(params[:id])

    respond_with permission,
                 location: -> { context_context_api_client_permissions_path(@context) },
                 notice: 'The API Client Permission has been deleted.'
  end

  private

  def set_context
    @context = Context.find(params[:context_id])
  end

  def permission_params
    params
      .require(:context_api_client_permission)
      .permit(:api_client_id, :view)
  end
end
