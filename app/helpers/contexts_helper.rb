module ContextsHelper
  def context_links(ids)
    ids.sort.map do |context_id|
      link_to context_id, context_path(context_id)
    end.join(', ').html_safe
  end
end
