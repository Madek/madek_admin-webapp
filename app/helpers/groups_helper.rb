module GroupsHelper

  def group_name(group)
    if group.institutional_name and not group.institutional_name.empty?
      "#{group.name} (#{group.institutional_name})"
    else
      group.name
    end
  end

end
