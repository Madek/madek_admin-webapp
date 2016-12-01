module MediaFilesHelper
  def conversion_status_label(media_file)
    zencoder_job = media_file
                          .zencoder_jobs
                          .first
    ok_label = [:success, 'OK']
    label_type, label_text =
      if zencoder_job
        if zencoder_job.state == 'submitted'
          [:info, zencoder_job.state]
        elsif zencoder_job.state == 'failed'
          [:danger, '1 failure']
        elsif (count = media_file.missing_formats.size) > 0
          [:warning, "#{count} missing #{'format'.pluralize(count)}"]
        else
          ok_label
        end
      else
        ok_label
      end

    content_tag :span, label_text, class: ['label', "label-#{label_type}"]
  end
end
