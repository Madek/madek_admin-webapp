module Concerns
  module LocalizedFieldParams
    extend ActiveSupport::Concern

    included do
      define_method :localized_field_params do
        resource_class = controller_name.classify.constantize
        {}.tap do |permitted_attributes|
          resource_class.localized_fields.each do |lf|
            permitted_attributes[lf] = I18n.available_locales
          end
        end
      end
    end
  end
end
