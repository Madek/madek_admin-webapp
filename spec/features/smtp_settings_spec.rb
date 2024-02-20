require 'spec_helper'
require 'spec_helper_feature'

feature 'SMTP Settings' do
  scenario 'Updating works' do
    visit smtp_settings_path
    click_on('Edit')
    check('smtp_settings[is_enabled]')
    fill_in('smtp_settings[domain]', with: 'domain')
    click_on('Save')
    expect(find('tr', text: 'is_enabled').all('td')[1].text).to eq 'true'
    expect(find('tr', text: 'domain').all('td')[1].text).to eq 'domain'
  end
end
