class XmpNamespacesController < ApplicationController
  include LocalizedFieldParams
  self.admin_permission_key = :io

  def index
    @xmp_namespaces = XmpNamespace.sorted.page(page_params).per(16)
  end

  def show
    @xmp_namespace = XmpNamespace.find(params[:id])
  end

  def new
    @xmp_namespace = XmpNamespace.new
  end

  def edit
    @xmp_namespace = XmpNamespace.find(params[:id])
  end

  def create
    xmp_namespace = XmpNamespace.create!(xmp_namespace_params)

    respond_with xmp_namespace, location: (lambda do
      xmp_namespace_path(xmp_namespace)
    end)
  end

  define_update_action_for(XmpNamespace)
  define_destroy_action_for(XmpNamespace)

  private

  def xmp_namespace_params
    params.require(:xmp_namespace).permit(:prefix, :uri, :is_managed, localized_field_params)
  end

  alias_method :update_xmp_namespace_params, :xmp_namespace_params
end
