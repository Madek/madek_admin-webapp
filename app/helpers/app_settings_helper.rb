module AppSettingsHelper
  def convert_context_id_to_link(ids)
    return unless ids.present?
    html = []
    ids = Array.wrap(ids)
    html.concat(
      ids.map do |context_id|
        if (context = Context.find_by(id: context_id))
          link_to(context.label, context_path(context.id))
        else
          invalid_reference_tag(context_id)
        end
      end
    )
    html.join(', ').html_safe
  end

  def context_keys_as_links(ids)
    return unless ids.present?
    html = []
    html.concat(
      ids.map do |context_key_id|
        if (context_key = ContextKey.find_by(context_id: 'upload',
                                             meta_key_id: context_key_id))
          link_to(context_key.label, meta_key_path(context_key.meta_key))
        else
          invalid_reference_tag(context_key_id)
        end
      end
    )
    html.join(', ').html_safe
  end

  def collection_as_link(collection_id)
    if collection_id.present? &&
       (collection = Collection.find_by_id(collection_id))
        link_to collection.id, collection_path(collection.id)
    end
  end

  def invalid_reference_tag(id)
    content_tag(:span, "#{id} (invalid!)", class: 'text-danger')
  end
end
