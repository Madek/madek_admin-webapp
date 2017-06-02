class ApiClientsController < ApplicationController

  def index
    @api_clients = ApiClient.page(params[:page]).per(16)
    remember_vocabulary_url_params
  end

  def show
    find_api_client
    @user = @api_client.user
  end

  def edit
    find_api_client

    if params[:edited_api_client].present?
      @api_client.assign_attributes edited_api_client_params
    end
  end

  def new
    @api_client = ApiClient.new

    if params[:new_api_client].present?
      @api_client.assign_attributes new_api_client_params
    end
  end

  def update
    find_api_client

    if params.key?(:change_user)
      redirect_to users_path(
        edited_api_client: api_client_params.merge(id: @api_client.id)
      )
    else
      @api_client.update!(api_client_params)

      respond_with @api_client, location: -> { api_client_path(@api_client) }
    end
  end

  def create
    @api_client = ApiClient.new(api_client_params)
    if @api_client.user
      @api_client.save!

      respond_with @api_client, location: -> { api_clients_path }
    else
      redirect_to users_path(new_api_client: api_client_params.except(:password))
    end
  end

  def destroy
    find_api_client
    @api_client.destroy

    respond_with @api_client, location: -> { api_clients_path }
  end

  private

  def find_api_client
    @api_client = ApiClient.find(params[:id])
  end

  def api_client_params
    params.require(:api_client).permit(:login, :user_id, :password, :description)
  end

  def new_api_client_params
    params.require(:new_api_client).permit(:login, :user_id, :description)
  end

  def edited_api_client_params
    params.require(:edited_api_client).permit(:login, :user_id, :description)
  end
end
