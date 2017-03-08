module Concerns
  module MetaKeysMoving
    extend ActiveSupport::Concern

    # edits the id, even allowing change of vocabulary(!)

    def move_form
      @meta_key = MetaKey.find(params[:meta_key_id]).id
    end

    def move
      old_id = params[:meta_key_id]
      new_id = params[:new_meta_key_id]
      new_vocabulary_id = new_id.split(':').first
      ActiveRecord::Base.transaction do
        MetaKey.find(old_id).update_attributes!(
          id: new_id, vocabulary_id: new_vocabulary_id)
      end
      redirect_to meta_key_path new_id
    end

  end
end
