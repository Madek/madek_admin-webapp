class SmtpSettingsController < ApplicationController

  before_action do
    unless current_user.beta_tester_notifications?
      raise("Not allowed to use this feature.")
    end
  end

  ATTRIBUTES = ['is_enabled',
                'host_address',
                'port',
                'domain',
                'default_from_address',
                'sender_address',
                'authentication_type',
                'enable_starttls_auto',
                'openssl_verify_mode',
                'username',
                'password']

  def show
    smtp_settings_attrs = SmtpSetting.first.attributes
    smtp_settings_attrs.delete("id")
    @smtp_settings_attrs = rearrange_attrs(smtp_settings_attrs)
  end

  def edit
    @attributes = ATTRIBUTES
    @smtp_settings = SmtpSetting.first
  end

  def update
    smtp_settings = SmtpSetting.first
    smtp_settings.update(smtp_settings_params)
    redirect_to(smtp_settings_path)
  end

  private

  def smtp_settings_params
    params.require(:smtp_settings).permit(*ATTRIBUTES)
  end

  def rearrange_attrs(attrs)
    ATTRIBUTES.each_with_object({}) do |key, new_attrs|
      new_attrs[key] = attrs[key]
    end
  end

end
