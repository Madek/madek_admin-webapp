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
        if context_key = ContextKey.find_by(id: context_key_id)
          link_to meta_key_path(context_key.meta_key) do
            "#{context_key.meta_key_id} (#{context_key.context.label})"
          end
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

  def meta_key_ids_as_links(ids)
    return unless ids.present?
    html = []
    html.concat(
      ids.split(',').map(&:strip).map do |meta_key_id|
        meta_key = MetaKey
                    .with_type('MetaDatum::Keywords')
                    .find_by(id: meta_key_id)
        if meta_key
          link_to meta_key.id, meta_key_path(meta_key)
        else
          invalid_reference_tag(meta_key_id)
        end
      end
    )
    html.join(', ').html_safe
  end

  def invalid_reference_tag(id)
    content_tag(:span, "#{id} (invalid!)", class: 'text-danger')
  end

  def setting_header(field_name)
    field_name = field_name.to_s
    field_name = field_name.singularize if AppSetting.localized_field?(field_name)
    field_name.titleize
  end

  def locale_label(locale, arrow_code = '&rarr;')
    content_tag :em, "#{locale} #{arrow_code}".html_safe, class: 'locale-label'
  end
end
