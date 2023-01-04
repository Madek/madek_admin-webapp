require 'spec_helper'
require 'spec_helper_feature'
require_relative 'shared/admin_comments'

feature 'Admin Contexts' do
  let!(:context) { create :context_with_context_keys }
  let(:app_settings) { AppSetting.first.presence || create(:app_setting) }
  let(:usage_message) do
    'This context is used as: ' \
    'Extra Contexts for Entry View, ' \
    'Contexts for "List" View, ' \
    'Summary Context for Entry View, ' \
    'Extra Contexts for Collection View'
  end
  let(:collection_path) { contexts_path }

  scenario 'Adding a context' do
    visit contexts_path
    click_link 'Create Context'

    fill_in 'context[id]', with: 'test-id'
    fill_in 'context[labels][de]', with: 'label DE'
    fill_in 'context[labels][en]', with: 'label EN'
    fill_in 'context[descriptions][de]', with: 'description DE'
    fill_in 'context[descriptions][en]', with: 'description EN'
    fill_in 'context[admin_comment]', with: 'admin comment'
    click_button 'Create'

    expect(page).to have_content 'Id test-id'
    expect(page).to have_content 'Labels {"de"=>"label DE", "en"=>"label EN"}'
    expect(page).to have_content 'Descriptions ' \
                                 '{"de"=>"description DE", "en"=>"description EN"}'
    expect(page).to have_content 'Admin comment admin comment'
  end

  scenario 'Editing a context' do
    visit contexts_path

    within "[data-id='#{context.id}']" do
      click_link 'Edit'
    end

    expect(current_path).to eq edit_context_path(context)

    fill_in 'context[labels][de]', with: 'new label DE'
    fill_in 'context[labels][en]', with: 'new label EN'
    fill_in 'context[descriptions][de]', with: 'new description DE'
    fill_in 'context[descriptions][en]', with: 'new description EN'
    fill_in 'context[admin_comment]', with: 'new admin comment'

    click_button 'Create'

    expect(current_path).to eq context_path(context)
    expect(page).to have_content 'Labels ' \
                                 '{"de"=>"new label DE", "en"=>"new label EN"}'
    expect(page).to have_content 'Descriptions ' \
                                 '{"de"=>"new description DE", ' \
                                 '"en"=>"new description EN"}'
    expect(page).to have_content 'Admin comment new admin comment'
  end

  scenario 'Displaying details' do
    visit context_path(context)

    expect(page).to have_content "Id #{context.id}"
    expect(page).to have_content "Labels {\"de\"=>\"#{context.label}\"}"
    expect(page).to have_content 'Descriptions ' \
                                 "{\"de\"=>\"#{context.description}\"}"
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

    within "[data-id='#{context.id}'] + tr + tr" do
      expect(page).to have_content usage_message
    end

    visit context_path(context)

    expect(page).to have_content usage_message
  end

  scenario 'Duplicating Context' do
    new_label = Faker::Lorem.sentence
    new_description = Faker::Lorem.sentence
    visit context_path(context)
    click_on 'Duplicate Context'

    fill_in 'context[labels][de]', with: new_label
    fill_in 'context[descriptions][de]', with: new_description

    click_button 'Create'
    find('.alert', text: 'Success! Context was successfully created')

    new_context = Context.find \
      Rails.application.routes.recognize_path(current_path)[:id]

    table_rows = all('.table.edit-context-keys tbody tr')

    new_context.context_keys.each.with_index do |ck, i|
      row = table_rows[(i * 3)]
      expect(row).to have_content "#{ck.position} #{ck.id} #{ck.meta_key.id}"
    end
  end

  scenario 'Creating Context from Vocabulary' do
    new_label = Faker::Lorem.sentence
    new_description = Faker::Lorem.sentence
    visit vocabulary_path('madek_core')
    click_on 'Create Context'

    fill_in 'context[labels][de]', with: new_label
    fill_in 'context[descriptions][de]', with: new_description

    click_button 'Create'
    find('.alert', text: 'Success! Context was successfully created')

    new_context = Context.find \
      Rails.application.routes.recognize_path(current_path)[:id]

    table_rows = all('.table.edit-context-keys tbody tr')

    new_context.context_keys.each.with_index do |ck, i|
      row = table_rows[(i * 3)]
      expect(row).to have_content "#{ck.position} #{ck.id} #{ck.meta_key.id}"
    end
  end

  include_examples 'display admin comments on overview page'

  def update_app_settings_with_context
    app_settings.update(
      { context_for_entry_summary: context.id }.tap do |hash|
        %i(
          contexts_for_entry_extra
          contexts_for_collection_extra
          contexts_for_list_details
        ).each { |attr| hash[attr] = [context.id] }
      end
    )
  end
end
