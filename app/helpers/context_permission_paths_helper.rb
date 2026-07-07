module ContextPermissionPathsHelper
  def path_to_context_permission_form(object)
    class_name_underscored = object.class.base_class.name.underscore
    request_params = {
      context_id: session[:context_permission_context_id],
      "#{class_name_underscored}_id" => object.id
    }
    action_prefix =
      if session[:context_permission_is_persisted] == 'true'
        request_params[:id] = session[:context_permission_id]
        :edit
      else
        :new
      end

    method_name = "#{action_prefix}_context_" \
                  "context_#{class_name_underscored}_permission_path"

    send(method_name, request_params)
  end
end
