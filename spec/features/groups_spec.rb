require 'spec_helper'
require 'spec_helper_feature'

feature 'Admin Groups' do
  scenario 'Filtering/sorting groups by name' do
    visit groups_path
    fill_in 'search_terms', with: 'zhdk'
    click_button 'Apply'
    names = all('table tbody tr').map do |tr|
      expect(tr.find('td:first').text.downcase).to have_content 'zhdk'
    end
    expect(find_field('search_terms')[:value]).to eq 'zhdk'
    expect(names).to eq names.sort
  end

  scenario 'Filtering/sorting groups by text search ranking' do
    visit groups_path
    fill_in 'search_terms', with: 'zhdk'
    select 'Text search ranking', from: 'sort_by'
    click_button 'Apply'
    names = all('table tbody tr').map do |tr|
      expect(tr.find('td:first').text.downcase).to have_content 'zhdk'
    end
    expect(find_field('search_terms')[:value]).to eq 'zhdk'
    expect(find_field('sort_by')[:value]).to eq 'text_rank'
    expect(names).to eq names.sort
  end

  scenario 'Filtering/sorting groups by trigram search ranking' do
    visit groups_path
    fill_in 'search_terms', with: 'zhdk'
    select 'Trigram search ranking', from: 'sort_by'
    click_button 'Apply'
    names = all('table tbody tr').map do |tr|
      tr.all('td')[3].text
    end
    expect(find_field('search_terms')[:value]).to eq 'zhdk'
    expect(find_field('sort_by')[:value]).to eq 'trgm_rank'
    expect(names).to eq names.sort!
  end

  scenario 'Filtering groups by type' do
    visit groups_path
    select 'Group', from: 'type'
    click_button 'Apply'
    all('table tbody tr').each do |tr|
      expect(tr.all('td')[2].text).to eq 'Group'
    end
    expect(find_field('type')[:value]).to eq 'Group'
  end

  scenario 'Editing a group' do
    group = create :group
    visit group_path(group)
    click_link('Edit')
    fill_in 'group[name]', with: 'AWESOME GROUP'
    click_button 'Save'
    expect(page).to have_css('.alert-success')
    expect(page).to have_content('AWESOME GROUP')
  end

  scenario 'Creating a new group' do
    visit groups_path
    click_link 'Create group'
    fill_in 'group[name]', with: ''
    click_button 'Save'
    expect(page).to have_content 'An error occured'
    expect(page).to have_content 'code: 422'
    click_link 'Go back'
    fill_in 'group[name]', with: 'NEW AWESOME GROUP'
    click_button 'Save'
    expect(page).to have_css('.alert-success')
    expect(page).to have_content('NEW AWESOME GROUP')
  end

  scenario 'Editing a group' do
    group = create :group

    visit groups_path
    filter_group group

    within "[data-id='#{group.id}']" do
      click_link 'Edit'
    end
    expect(current_path).to eq edit_group_path(group)

    fill_in 'Name', with: 'New group name'
    click_button 'Save'
    expect(page).to have_css '.alert-success'
    expect(current_path).to eq group_path(group)
    expect(page).to have_content 'Name (name) New group name'
  end

  scenario 'Editing an Institutional Group' do
    group = create :institutional_group

    visit groups_path
    filter_group group

    within "[data-id='#{group.id}']" do
      expect(page).to have_content 'InstitutionalGroup'
      click_link 'Edit'
    end
    expect(current_path).to eq edit_group_path(group)

    fill_in 'Name', with: 'New institutional group name'
    click_button 'Save'
    expect(page).to have_css '.alert-success'
    expect(current_path).to eq group_path(group)
    expect(page).to have_content 'Name (name) New institutional group name'
  end

  scenario 'Editing an Authentication Group' do
    group = create :authentication_group

    visit groups_path
    filter_group group

    within "[data-id='#{group.id}']" do
      expect(page).to have_content 'AuthenticationGroup'
      click_link 'Edit'
    end
    expect(current_path).to eq edit_group_path(group)

    fill_in 'Name', with: 'New authentication group name'
    click_button 'Save'
    expect(page).to have_css '.alert-success'
    expect(current_path).to eq group_path(group)
    expect(page).to have_content 'Name (name) New authentication group name'
  end

  scenario 'Deleting a group with users' do
    group = create :group, :with_user
    visit group_path(group)
    click_link 'Delete'
    expect(page).to have_css('.alert-danger')
  end

  scenario 'Deleting a group without users' do
    group = create :group
    visit group_path(group)
    click_link 'Delete'
    expect(page).to have_css('.alert-success')
  end

  scenario 'Deleting a group with users' do
    group = create :group, :with_user
    visit group_path(group)
    expect(group_user_count).to eq 1
    click_link 'Delete'
    expect(page).to have_css('.alert-danger')
  end

  describe 'Adding an user to a group' do
    let(:group) { create :group }
    let(:user) { create :user }

    scenario 'when group already includes the user' do
      group.users << user

      visit group_path(group)
      within '#group-users' do
        expect(page).to have_content user.login
      end

      click_link 'Add user'
      expect(current_path).to eq users_path
      expect(page).to have_css '.alert-info'

      fill_in 'search_term', with: user.login
      click_button 'Apply'
      within "[data-id='#{user.id}']" do
        click_link 'Add to the Group'
      end

      expect(current_path).to eq group_path(group)
      within '.alert-danger' do
        expect(page).to have_content 'already belongs to this group'
      end
    end

    scenario 'when group does not include the user' do
      visit group_path(group)
      within '#group-users' do
        expect(page).not_to have_content user.login
      end

      click_link 'Add user'
      expect(current_path).to eq users_path
      expect(page).to have_css '.alert-info'

      fill_in 'search_term', with: user.login
      click_button 'Apply'
      within "[data-id='#{user.id}']" do
        click_link 'Add to the Group'
      end

      expect(current_path).to eq group_path(group)
      within '.alert-success' do
        expect(page).to have_content "The user #{user.login} has been added."
      end
    end
  end

  scenario 'Removing a user from a group' do
    group = create :group, :with_user
    visit group_path(group)
    expect(group_user_count).to eq 1
    click_link 'Remove from group'
    expect(page).to have_css('.alert-success')
    expect(group_user_count).to eq 0
  end

  scenario 'Filtering users belonging to a group' do
    group = create :group, :with_user
    group.users << create(:user, login: 'test')
    visit group_path(group)
    expect(group_user_count).to eq 2
    fill_in 'user[search_term]', with: 'test'
    click_button 'Filter'
    expect(group_user_count).to eq 1
    within 'table#group-users' do
      expect(page).to have_content 'test'
    end
  end

  scenario 'Merging institutional group to regular group' do
    merge_to = create :group
    to_merge = Group.departments.first
    visit group_path(to_merge)
    click_link 'Merge to'
    fill_in 'id_receiver', with: merge_to.id
    click_button 'Merge'
    expect(page).to have_content 'An error occured'
    expect(page).to have_content 'code: 404'
  end

  scenario 'Merging institutional groups' do
    merge_to = Group.departments.last
    to_merge = Group.departments.first
    to_merge.users << create(:user)
    visit group_path(merge_to)
    expect(group_user_count).to eq 0
    visit group_path(to_merge)
    expect(group_user_count).to eq 1
    click_link 'Merge to'
    fill_in 'id_receiver', with: merge_to.id
    click_button 'Merge'
    expect(page).to have_css('.alert-success')
    visit group_path(merge_to)
    expect(group_user_count).to eq 1
  end

  scenario 'Authentication Group cannot be deleted' do
    group = create :authentication_group

    visit groups_path
    filter_group group
    within "[data-id='#{group.id}']" do
      expect(page).not_to have_link 'Delete'
    end

    visit group_path(group)
    expect(page).not_to have_link 'Delete'
  end

  scenario 'Admin is not able to add members to Authentication Group' do
    group = create :authentication_group

    visit group_path(group)

    expect(page).not_to have_link 'Add user'
  end

  scenario 'Admin is not able to remove members from Authentication Group' do
    group = create :authentication_group, :with_user

    visit group_path(group)

    expect(page).not_to have_link 'Remove from group'
  end

  scenario 'Group without users has proper text in table' do
    group = create :group

    visit group_path(group)

    within '#group-users' do
      expect(page).to have_content 'No users'
    end
  end

  def group_user_count
    all('table#group-users tbody tr:not(.empty-collection)').count
  end

  def filter_group(group)
    fill_in :search_terms, with: group.name
    select 'Name', from: :sort_by
    click_button 'Apply'
  end
end
