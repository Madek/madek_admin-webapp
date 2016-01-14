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
  end

  def new
    @api_client = ApiClient.new
  end

  def update
    find_api_client
    @api_client.update!(api_client_params)

    respond_with @api_client, location: -> { api_client_path(@api_client) }
  end

  def create
    api_client = ApiClient.create!(api_client_params)

    respond_with api_client, location: -> { api_clients_path }
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
    params.require(:api_client).permit!
  end
end
