require 'spec_helper'
require 'spec_helper_feature'

feature 'Rename and move a MetaKey to another Vocabulary' do
  scenario 'it works' do
    visit meta_key_path('toni:toni_blickrichtung')
    click_on 'Move'
    fill_in 'new_meta_key_id', with: 'zett:moved-key'
    click_on 'Move'
    expect(current_path).to be == '/admin/meta_keys/zett:moved-key'
  end
end
