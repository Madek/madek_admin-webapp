require 'spec_helper'
require 'spec_helper_feature'

feature 'Admin Context API Client Permissions' do
  given!(:context) { create(:context) }
  given!(:api_client) { create(:api_client) }
  given!(:api_client_permission) { create(:context_api_client_permission, :viewable) }
  given!(:updated_api_client) { create(:api_client) }

  scenario 'Creating a permission' do
    visit contexts_path

    within('table tbody tr', text: context.id) do
      click_link 'API Client Permissions'
    end
    click_link 'Create API Client Permission'
    expect(page).to have_content 'New API Client Permission'
    expect(page).not_to have_field('Can view?')
    expect(page).not_to have_button 'Save'
    click_link 'Choose API Client'

    expect(current_path).to eq(api_clients_path)
    expect_info_alert

    within('table tbody tr', text: api_client.login) do
      click_link 'Grant Context Permission'
    end

    expect(current_path).to eq(new_context_context_api_client_permission_path(context))
    expect(page).to have_content 'New API Client Permission'

    expect(page).to have_field('Context ID', disabled: true, with: context.id)
    expect(page).to have_field('API Client', disabled: true, with: api_client.login)
    expect(page).to have_checked_field('context_api_client_permission[view]')

    click_button 'Save'

    expect(page).to have_css('.alert-success', text: 'The API Client Permission has been created.')
    expect(page).to have_css('table tbody tr', text: "#{api_client.login} true")
  end

  scenario 'Creating a permission for the same API Client '\
           'and canceling the process', browser: :firefox do
    visit contexts_path

    within('table tbody tr', text: api_client_permission.context_id) do
      click_link 'API Client Permissions'
    end
    click_link 'Create API Client Permission'
    click_link 'Choose API Client'

    expect_info_alert
    within('table tbody tr', text: api_client_permission.api_client.login) do
      expect(page).to have_css('a.disabled', text: 'Grant Context Permission')
      click_link 'Grant Context Permission'
    end

    expect(page)
      .to have_current_path(api_clients_path(add_to_context_id: api_client_permission.context_id,
                                             is_persisted: false))

    click_link 'Cancel', match: :first

    expect(page).to have_current_path(api_clients_path)
    expect_no_info_alert
  end

  scenario 'Editing a permission' do
    visit contexts_path

    within('table tbody tr', text: api_client_permission.context.id) do
      click_link 'API Client Permissions'
    end
    within('table tbody tr', text: api_client_permission.api_client.login) do
      click_link 'Edit'
    end

    expect(page).to have_content 'Edit API Client Permission'
    expect(page).to have_button 'Save'
    expect(page)
      .to have_field('Context ID', disabled: true, with: api_client_permission.context.id)
    expect(page)
      .to have_field('API Client', disabled: true, with: api_client_permission.api_client.login)
    expect(page).to have_checked_field('context_api_client_permission[view]')

    click_link 'Choose API Client'

    expect(current_path).to eq(api_clients_path)
    expect_info_alert

    within('table tbody tr', text: updated_api_client.login) do
      click_link 'Grant Context Permission'
    end

    expect(current_path).to eq(
      edit_context_context_api_client_permission_path(api_client_permission.context_id,
                                                      api_client_permission))
    expect(page).to have_content 'Edit API Client Permission'
    expect(page)
      .to have_field('Context ID', disabled: true, with: api_client_permission.context.id)
    expect(page)
      .to have_field('API Client', disabled: true, with: updated_api_client.login)
    expect(page).to have_checked_field('context_api_client_permission[view]')

    uncheck 'Can view?'
    click_button 'Save'

    expect(page).to have_css('.alert-success', text: 'The API Client Permission has been updated.')
    expect(page).to have_css('table tbody tr', text: "#{updated_api_client.login} false")
  end

  scenario 'Deleting a permission', browser: :firefox do
    visit contexts_path

    within('table tbody tr', text: api_client_permission.context_id) do
      click_link 'API Client Permissions'
    end

    within('table tbody tr', text: api_client_permission.api_client.login) do
      accept_confirm { click_link 'Delete' }
    end

    expect(page).to have_css('.alert-success', text: 'The API Client Permission has been deleted.')
    expect(page).not_to have_css('table tbody tr', text: updated_api_client.login)
  end
end

def expect_info_alert
  within '.alert-info' do
    expect(page).to have_link('cancel', href: api_clients_path)
  end
end

def expect_no_info_alert
  expect(page).not_to have_css('.alert-info')
end
