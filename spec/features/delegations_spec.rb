require 'spec_helper'
require 'spec_helper_feature'

feature 'Delegations' do
  given(:new_delegation) { build :delegation }
  given(:delegation) { create :delegation }

  scenario 'Creating' do
    visit '/admin/delegations'

    expect(page).to have_text('Delegations (0)')
    expect(page).to have_text('No delegations')
    expect(page).to have_no_text('No members')
    click_link 'Create delegation'

    fill_in 'Name', with: new_delegation.name
    fill_in 'Description', with: new_delegation.description
    fill_in 'Admin comment', with: new_delegation.admin_comment

    click_button 'Save'

    expect(page).to have_css('.alert-success')
    expect(page).to have_text "Name [name] #{new_delegation.name}"
    expect(page).to have_text "Description [description] #{new_delegation.description}"
    expect(page).to have_text "Admin comment [admin_comment] #{new_delegation.admin_comment}"
    expect(page).to have_text 'Users (0)'
    expect(page).to have_text 'Groups (0)'

    visit '/admin/delegations'

    expect(page).to have_text('Delegations (1)')
    expect(page).to have_no_text('No delegations')
    expect_row(new_delegation.name, 'No members', 0)
  end

  scenario 'Editing' do
    delegation

    new_name = Faker::Team.name
    new_description = Faker::Lorem.sentence
    new_admin_comment = Faker::Lorem.sentence

    visit '/admin/delegations'

    within "tr[data-id='#{delegation.id}']" do
      click_link 'Edit'
    end

    expect(page).to have_text("Edit Delegation #{delegation.name}")

    fill_in 'Name', with: new_name
    fill_in 'Description', with: new_description
    fill_in 'Admin comment', with: new_admin_comment
    click_button 'Save'

    expect(page).to have_css('.alert-success')
    expect(page).to have_text "Name [name] #{new_name}"
    expect(page).to have_text "Description [description] #{new_description}"
    expect(page).to have_text "Admin comment [admin_comment] #{new_admin_comment}"
  end

  scenario 'Deleting', browser: :firefox do
    delegation

    visit '/admin/delegations'

    expect(page).to have_text('Delegations (1)')
    expect(page).to have_no_text('No delegations')
    expect_row(delegation.name, 'No members', 0)

    within "tr[data-id='#{delegation.id}']" do
      accept_alert { click_link 'Delete' }
    end

    expect(page).to have_css('.alert-success')
    expect(page).to have_text('Delegations (0)')
    expect(page).to have_text('No delegations')
    expect(page).to have_no_text('No members')
  end

  describe 'Listing' do
    scenario 'Displaying correct members count' do
      delegation.users << [create(:user), create(:user)]
      delegation.groups << create(:group, :with_user)

      visit '/admin/delegations'
      expect_row(delegation.name, '3 Users (incl. 1 group member)', 0)
    end

    scenario 'Displaying correct members count if there is only one direct member' do
      delegation.users << create(:user)

      visit '/admin/delegations'
      expect_row(delegation.name, '1 User (incl. 0 group members)', 0)
    end

    scenario 'Displaying correct members count if there is only one group member' do
      delegation.groups << create(:group, :with_user)

      visit '/admin/delegations'
      expect_row(delegation.name, '1 User (incl. 1 group member)', 0)
    end

    scenario 'Displaying correct resources count' do
      create(:delegation,
             :with_media_entries,
             :with_collections,
             name: 'My Delegation',
             entries_amount: 3)

      visit '/admin/delegations'
      expect_row('My Delegation', 'No members', 5)
    end

    scenario 'Displaying correct resources count if there are only 2 media entries' do
      create(:delegation,
             :with_media_entries,
             name: 'My Delegation',
             entries_amount: 2)

      visit '/admin/delegations'
      expect_row('My Delegation', 'No members', 2)
    end

    scenario 'Displaying correct resources count if there are only 3 collections' do
      create(:delegation,
             :with_collections,
             name: 'My Delegation',
             collections_amount: 3)

      visit '/admin/delegations'
      expect_row('My Delegation', 'No members', 3)
    end
  end

  def expect_row(name, members_count, resources_count)
    expect(page).to have_css('tr', text: "#{name} #{members_count} #{resources_count}")
  end
end
