module DelegationsHelper
  def delegation_members_column(delegation)
    users_count = delegation.users.count
    users_part = pluralize(users_count, 'User')
    groups_count = delegation.groups.count
    groups_part = pluralize(groups_count, 'Group')
    total_count = users_count + groups_count

    if total_count.zero?
      content_tag :span, 'No members', class: 'text-muted'
    else
      pluralize(users_count + groups_count, 'Member') + " (#{[users_part, groups_part].join(', ')})"
    end
  end

  def delegation_links(delegations)
    capture_haml do
      haml_tag('ul') do
        delegations.order(:name).map do |delegation|
          haml_tag('li') { haml_concat link_to delegation.name, delegation_path(delegation) }
        end
      end
    end
  end
end
