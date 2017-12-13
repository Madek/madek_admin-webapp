module Concerns
  module LocalizedFieldParams
    def localized_field_params_for(klass)
      {}.tap do |permitted_attributes|
        klass.localized_fields.each do |lf|
          permitted_attributes[lf] = I18n.available_locales
        end
      end
    end
  end
end
