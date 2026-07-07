require 'spec_helper'
require 'spec_helper_feature'

feature 'Admin Context Group Permissions' do
  let!(:context) { create :context }
  let(:group_permission) do
    create(:context_group_permission, context: context, use: false, view: true)
  end
  let(:new_group) { create :group }

  scenario 'Creating a permission' do
    visit contexts_path

    within find('table tbody tr', text: context.id) do
      click_link 'Group Permissions'
    end
    click_link 'Create Group Permission'
    expect(page).to_not have_button 'Save'
    click_link 'Choose group'

    expect(current_path).to eq(groups_path)

    filter_with(new_group.name)

    within find('table tbody tr', text: new_group.name) do
      click_link 'Grant Context Permission'
    end

    expect(current_path).to eq(
      new_context_context_group_permission_path(context.id))

    click_button 'Save'

    expect(page).to have_css(
      '.alert-success',
      text: 'The Context Group Permission has been created.')
  end

  scenario 'Editing a permission' do
    visit contexts_path

    within find('table tbody tr', text: group_permission.context.id) do
      click_link 'Group Permissions'
    end
    within find('table tbody tr', text: group_permission.group.name) do
      click_link 'Edit'
    end
    expect(page).to have_button 'Save'
    click_link 'Choose group'

    expect(current_path).to eq(groups_path)

    filter_with(new_group.name)

    within find('table tbody tr', text: new_group.name) do
      click_link 'Grant Context Permission'
    end

    expect(current_path).to eq(
      edit_context_context_group_permission_path(
        group_permission.context_id, group_permission))

    check 'Can use?'
    uncheck 'Can view?'

    click_button 'Save'

    group_permission.reload
    expect(group_permission.group_id).to eq new_group.id
    expect(group_permission.use).to be true
    expect(group_permission.view).to be false

    expect(page).to have_css(
      '.alert-success',
      text: 'The Context Group Permission has been updated.')
  end

  def filter_with(group_name)
    fill_in 'search_terms', with: group_name
    click_button 'Apply'
  end
end
