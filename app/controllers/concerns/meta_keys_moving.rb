module MetaKeysMoving
  extend ActiveSupport::Concern

  # edits the id, even allowing change of vocabulary(!)
  WARNING = <<-END.strip_heredoc
    This should only be used very rarely (or during initial setup).
    The ID is normally expected to not change, e.g. API clients might break.
  END

  def move_form
    flash.now[:warning] = WARNING
    @meta_key = MetaKey.find(params[:meta_key_id]).id
  end

  def move
    old_id = params[:meta_key_id]
    new_id = params[:new_meta_key_id]
    new_vocabulary_id = new_id.split(':').first
    ActiveRecord::Base.transaction do
      mk = MetaKey.find(old_id)
      mk.update!(
        id: new_id, vocabulary_id: new_vocabulary_id,
        admin_comment: (mk.admin_comment || '') +
          "\n[LOG: was renamed from `#{old_id}` on #{Time.now.utc.to_json}]"
      )
    end
    redirect_to meta_key_path new_id
  end

end
