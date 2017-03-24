module GroupsHelper
  def group_links(groups)
    groups.order(:name).map do |group|
      link_to group.name, group_path(group)
    end.join(', ').html_safe
  end
end
