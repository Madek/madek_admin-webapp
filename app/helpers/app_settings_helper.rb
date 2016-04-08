module AppSettingsHelper
  def convert_context_id_to_link(id)
    return unless id
    if id.is_a?(Array)
      html = []
      Context.where(id: id).each do |context|
        html << link_to(context.label, context_path(context.id))
      end
      html.join(', ').html_safe
    else
      link_to Context.find(id).label, context_path(id)
    end
  end
end
