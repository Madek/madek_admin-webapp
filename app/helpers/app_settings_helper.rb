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
          content_tag(:span, "#{context_id} (invalid!)", class: 'text-danger')
        end
      end
    )
    html.join(', ').html_safe
  end

  def context_keys_as_links(ids)
    return unless ids
    html = []
    ContextKey.where(context_id: 'upload', meta_key_id: ids).each do |context_key|
      html << link_to(context_key.label, meta_key_path(context_key.meta_key))
    end
    html.join(', ').html_safe
  end
end
