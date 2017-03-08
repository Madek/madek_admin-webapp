module MetaKeysHelper
  def second_step_label(column, f, &block)
    css_class = ' text-info' if @second_step_columns.try(:include?, column)
    f.label column, class: "control-label#{css_class}", &block
  end
end
