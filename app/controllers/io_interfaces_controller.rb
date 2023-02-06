class IoInterfacesController < ApplicationController
  def index
    @io_interfaces = IoInterface.page(page_params).per(16)
  end

  def show
    @io_interface = IoInterface.find(params[:id])
  end

  def new
    @io_interface = IoInterface.new
  end

  def create
    io_interface = IoInterface.create!(io_interface_params)

    respond_with io_interface, location: (lambda do
      io_interfaces_path
    end)
  end

  define_destroy_action_for(IoInterface)

  private

  def io_interface_params
    params.require(:io_interface).permit(:id, :description)
  end
end
