module PreviousResource
  private

  def try_redirect_to_subsequent_resource
    resource = model_klass.find_by_previous_id(params[:id])
    raise unless resource
    redirect_to resource
  end

  def model_klass
    controller_name.classify.constantize
  end
end
