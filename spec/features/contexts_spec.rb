require 'spec_helper'
require 'spec_helper_feature'

feature 'Admin Contexts' do
  let!(:context) { create :context_with_context_keys }
  let(:app_settings) { AppSetting.first.presence || create(:app_setting) }
  let(:usage_message) do
    "This context is used as: \
     Summary Context for Detail View, \
     Extra Contexts for Detail View, \
     Contexts for \"List\" View"
  end

  scenario 'Editing a context' do
    visit contexts_path

    within "[data-id='#{context.id}']" do
      click_link 'Edit'
    end

    expect(current_path).to eq edit_context_path(context)

    fill_in 'context[label]', with: 'new label'
    fill_in 'context[description]', with: 'new description'
    fill_in 'context[admin_comment]', with: 'new admin comment'

    click_button 'Save'

    expect(current_path).to eq context_path(context)
    expect(page).to have_content 'Label new label'
    expect(page).to have_content 'Description new description'
    expect(page).to have_content 'Admin comment new admin comment'
  end

  scenario 'Displaying details' do
    visit context_path(context)

    expect(page).to have_content "Id #{context.id}"
    expect(page).to have_content "Label #{context.label}"
    expect(page).to have_content "Description #{context.description}"
    expect(page).to have_content "Admin comment #{context.admin_comment}"
  end

  scenario 'Deleting a context' do
    visit contexts_path

    all('tr[data-id]').each do |row|
      expect(row).to have_link 'Delete'
    end

    within "tr[data-id='#{context.id}']" do
      click_link 'Delete'
    end

    expect(page).to have_css '.alert-success'
    expect(page).not_to have_css "tr[data-id='#{context.id}']"
  end

  scenario 'Adding a MetaKey' do
    visit context_path(context)

    within('.panel') { click_link 'Edit' }
    click_link 'Add MetaKey'

    expect(current_path).to eq meta_keys_path
    expect(page).to have_css '.alert-info'

    first('a', text: 'Add to the Context').click

    expect(current_path).to eq edit_context_path(context)
    expect(page).to have_css '.alert-success'

    visit meta_keys_path
    expect(page).not_to have_css '.alert-info'
  end

  scenario 'Displaying info about context usage in UI' do
    update_app_settings_with_context

    visit contexts_path

    within "[data-id='#{context.id}'] + tr" do
      expect(page).to have_content usage_message
    end

    visit context_path(context)

    expect(page).to have_content usage_message
  end

  def update_app_settings_with_context
    app_settings.update(
      { context_for_show_summary: context.id }.tap do |hash|
        %i(contexts_for_show_extra contexts_for_list_details).each do |attr|
          hash[attr] = [context.id]
        end
      end
    )
  end
end
