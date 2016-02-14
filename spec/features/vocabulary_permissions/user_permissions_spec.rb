require 'spec_helper'
require 'spec_helper_feature'

feature 'Admin Vocabulary User Permissions' do
  let!(:admin_user) { create :admin_user, password: 'password' }
  let(:vocabulary) { Vocabulary.find('archhist') }
  let(:user_permission) do
    create(:vocabulary_user_permission, use: false, view: true)
  end

  scenario 'Creating a permission' do
    visit vocabularies_path

    within find('table tbody tr', text: vocabulary.id) do
      click_link 'User Permissions'
    end
    click_link 'Create User Permission'
    expect(page).to_not have_button 'Save'
    click_link 'Choose user'

    expect(current_path).to eq(users_path)

    within find('table tbody tr', text: admin_user.login) do
      click_link 'Grant Vocabulary Permission'
    end

    expect(current_path).to eq(
      new_vocabulary_vocabulary_user_permission_path(vocabulary.id))

    click_button 'Save'

    expect(page).to have_css(
      '.alert-success',
      text: 'The Vocabulary User Permission has been created.')
  end

  scenario 'Editing a permission' do
    visit vocabularies_path(search_term: user_permission.vocabulary.id)

    within find('table tbody tr', text: user_permission.vocabulary.id) do
      click_link 'User Permissions'
    end
    within find('table tbody tr', text: user_permission.user.login) do
      click_link 'Edit'
    end
    expect(page).to have_button 'Save'
    click_link 'Choose user'

    expect(current_path).to eq(users_path)

    within find('table tbody tr', text: admin_user.login) do
      click_link 'Grant Vocabulary Permission'
    end

    expect(current_path).to eq(
      edit_vocabulary_vocabulary_user_permission_path(
        user_permission.vocabulary_id, user_permission))

    check 'Can use?'
    uncheck 'Can view?'

    click_button 'Save'

    user_permission.reload
    expect(user_permission.user_id).to eq(admin_user.id)
    expect(user_permission.use).to be true
    expect(user_permission.view).to be false

    expect(page).to have_css(
      '.alert-success',
      text: 'The Vocabulary User Permission has been updated.')
  end
end
