require 'spec_helper'
require 'spec_helper_feature'

feature 'Rename and move a MetaKey to another Vocabulary' do
  scenario 'it works' do
    meta_key_id = 'toni:toni_blickrichtung'
    new_meta_key_id = 'zett:moved-key'
    MetaKey.find(meta_key_id).update!(admin_comment: 'some old comment')
    visit meta_key_path(meta_key_id)
    click_on 'Move'
    fill_in 'new_meta_key_id', with: new_meta_key_id
    click_on 'Move'
    expect(current_path).to be == meta_key_path(new_meta_key_id)
    admin_comment = MetaKey.find(new_meta_key_id).admin_comment
    expect(admin_comment).to include('some old comment')
    expect(admin_comment).to include("\n[LOG: was renamed from `#{meta_key_id}`")
  end
end
