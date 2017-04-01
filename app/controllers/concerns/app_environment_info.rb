require_relative Rails.root.join './lib/get_system_info.rb'

module Concerns
  module AppEnvironmentInfo
    extend ActiveSupport::Concern

    private

    def syscall(cmd)
      begin; `#{cmd}`.chomp.strip; rescue; nil; end
    end

    def get_madek_base_info
      app_settings = AppSettings.first
      zencoder_api_key = Settings.zencoder_api_key.present?
      {
        site_title: app_settings.try(:site_title),
        base_url: Settings.madek_external_base_url,
        zencoder: (if Settings.zencoder_enabled && Settings.zencoder_test_mode
                     zencoder_api_key ? 'TEST MODE!' : 'TEST MODE BUT NO KEY!'
                   elsif Settings.zencoder_enabled
                     zencoder_api_key ? 'OK' : 'NO KEY!'
                   else
                     'NO!'
                   end),
        zhdk_integration: Settings.zhdk_integration ? true : nil
      }
    end

    def get_pg_version
      ActiveRecord::Base.connection.execute('SELECT version();').to_a.first
    end

  end
end
