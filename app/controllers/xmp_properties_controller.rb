class XmpPropertiesController < ApplicationController
  include LocalizedFieldParams
  self.admin_permission_key = :io

  before_action :find_xmp_namespace

  def new
    @xmp_property = @xmp_namespace.xmp_properties.new
  end

  def edit
    @xmp_property = @xmp_namespace.xmp_properties.find(params[:id])
  end

  def create
    xmp_property = @xmp_namespace.xmp_properties.create!(xmp_property_params)

    respond_with xmp_property, location: (lambda do
      xmp_namespace_path(@xmp_namespace)
    end)
  end

  def update
    xmp_property = @xmp_namespace.xmp_properties.find(params[:id])
    xmp_property.update!(xmp_property_params)

    respond_with xmp_property, location: (lambda do
      xmp_namespace_path(@xmp_namespace)
    end)
  end

  def destroy
    xmp_property = @xmp_namespace.xmp_properties.find(params[:id])
    unless xmp_property.destroy
      flash[:error] = xmp_property.errors.full_messages.join(', ')
    end

    redirect_to xmp_namespace_path(@xmp_namespace)
  end

  private

  def find_xmp_namespace
    @xmp_namespace = XmpNamespace.find(params[:xmp_namespace_id])
  end

  def xmp_property_params
    params.require(:xmp_property).permit(:name, :value_type, :position, localized_field_params)
  end
end
