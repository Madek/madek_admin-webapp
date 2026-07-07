require 'spec_helper'
require 'spec_helper_feature'

feature 'Admin Context User Permissions' do
  let!(:admin_user) { create :admin_user, password: 'password' }
  let!(:context) { create :context }
  let(:user_permission) do
    create(:context_user_permission, context: context, use: false, view: true)
  end

  scenario 'Creating a permission' do
    visit contexts_path

    within find('table tbody tr', text: context.id) do
      click_link 'User Permissions'
    end
    click_link 'Create User Permission'
    expect(page).to_not have_button 'Save'
    click_link 'Choose user'

    expect(current_path).to eq(users_path)

    within find('table tbody tr', text: admin_user.login) do
      click_link 'Grant Context Permission'
    end

    expect(current_path).to eq(
      new_context_context_user_permission_path(context.id))

    click_button 'Save'

    expect(page).to have_css(
      '.alert-success',
      text: 'The Context User Permission has been created.')
  end

  scenario 'Editing a permission' do
    visit contexts_path

    within find('table tbody tr', text: user_permission.context.id) do
      click_link 'User Permissions'
    end
    within find('table tbody tr', text: user_permission.user.login) do
      click_link 'Edit'
    end
    expect(page).to have_button 'Save'
    click_link 'Choose user'

    expect(current_path).to eq(users_path)

    within find('table tbody tr', text: admin_user.login) do
      click_link 'Grant Context Permission'
    end

    expect(current_path).to eq(
      edit_context_context_user_permission_path(
        user_permission.context_id, user_permission))

    check 'Can use?'
    uncheck 'Can view?'

    click_button 'Save'

    user_permission.reload
    expect(user_permission.user_id).to eq(admin_user.id)
    expect(user_permission.use).to be true
    expect(user_permission.view).to be false

    expect(page).to have_css(
      '.alert-success',
      text: 'The Context User Permission has been updated.')
  end
end
