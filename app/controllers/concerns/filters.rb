module Filters
  extend ActiveSupport::Concern

  included do
    @collection_var = "@#{self.name.chomp('Controller').tableize}"
  end

  def filter_with(*filters)
    filters.each do |filter|
      set_collection(
        if filter.is_a?(Hash)
          value = filter_value(filter.keys.first)
          next if value.blank?

          collection.send(filter.values.first, value)
        elsif filter.is_a?(Symbol)
          value = filter_value(filter)
          next if value.blank?

          collection.where(filter => value)
        end
      )
    end
  end

  private

  def collection
    instance_variable_get(self.class.instance_variable_get('@collection_var'))
  end

  def set_collection(obj)
    instance_variable_set(
      self.class.instance_variable_get('@collection_var'),
      obj
    )
  end
end
