module DelegationsHelper
  def delegation_members_column(delegation)
    members_count = delegation.members_count
    group_members_count = delegation.group_members_count

    if members_count.zero?
      content_tag :span, 'No members', class: 'text-muted'
    else
      pluralize(members_count, 'User').html_safe +
        content_tag(:small, nil, class: 'text-muted show') do
          " (incl. #{pluralize(group_members_count, 'group member')})"
        end
    end
  end
end
