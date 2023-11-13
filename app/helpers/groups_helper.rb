module GroupsHelper

  def group_name(group)
    if group.institutional_name and not group.institutional_name.empty?
      "#{group.name} (#{group.institutional_name})"
    else
      group.name
    end
  end

  def group_links(groups)
    capture_haml do
      content_tag('ul') do
        groups.order(:name).map do |group|
          concat content_tag('li') { link_to group_name(group), group_path(group) }
        end
      end
    end
  end

end
