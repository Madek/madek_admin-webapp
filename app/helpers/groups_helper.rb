module GroupsHelper

  def group_links(groups)
    capture_haml do
      content_tag('ul') do
        groups.order(:name).map do |group|
          concat content_tag('li') { concat link_to group.name, group_path(group) }
        end
      end
    end
  end

end
