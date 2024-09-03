module HandleIsDeletedParam
  extend ActiveSupport::Concern

  included do
    private def handle_is_deleted_param(resources)
      param_value = params[:filter].try(:[], :is_deleted)

      if param_value.blank?
        resources.where('deleted_at IS NULL OR deleted_at IS NOT NULL')
      elsif param_value == '1'
        resources.deleted
      elsif param_value == '0'
        resources.not_deleted
      end
    end
  end
end
