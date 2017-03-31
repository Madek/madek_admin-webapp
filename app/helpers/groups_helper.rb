module GroupsHelper

  def group_links(groups)
    capture_haml do
      haml_tag('ul') do
        groups.order(:name).map do |group|
          haml_tag('li') { haml_concat link_to group.name, group_path(group) }
        end
      end
    end
  end

end
