module OrderHelper
  def move_buttons(object, labels: true)
    directions = %i(to_top up down to_bottom).select do |direction|
      object.respond_to?("move_#{direction}") \
        && check_policy?(object, "move_#{direction}?")
    end
    directions.each do |direction|
      concat move_button(object, direction, labels)
    end
    nil
  end

  def move_button(object, direction, label)
    title = "Move #{direction.to_s.split('_').join(' ')}"
    body = title if label
    url = url_for(action: "move_#{direction}",
                  controller: object.class.name.underscore.pluralize,
                  id: object)
    css_class = "move_#{direction}".dasherize
    icon =
      case direction
      when :to_top    then 'glyphicon-arrow-up'
      when :up        then 'glyphicon-chevron-up'
      when :down      then 'glyphicon-chevron-down'
      when :to_bottom then 'glyphicon-arrow-down'
      end
    render('shared/move_button',
           body: body,
           url: url,
           css_class: css_class,
           icon: icon,
           title: title)
  end

  def check_policy?(object, action)
    if Pundit.policy(current_user, object)
      policy(object).send(action)
    else
      true
    end
  end
end
