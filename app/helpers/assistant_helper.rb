module AssistantHelper
  def truncate_query(query, lines_count = 5)
    lines = query.split("\n")
    suffix = lines.size > lines_count ? '...' : nil
    [lines.first(lines_count), suffix]
      .compact
      .join("\n")
      .gsub(' ', '&nbsp;')
      .gsub("\n", '<br>')
      .html_safe
  end
end
