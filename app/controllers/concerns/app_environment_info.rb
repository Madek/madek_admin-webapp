require_relative Rails.root.join './lib/get_system_info.rb'
require 'sys/filesystem'
include Sys

MADEK_FILE_STORES = {
  DEFAULT_STORAGE_DIR: Madek::Constants::DEFAULT_STORAGE_DIR,
  FILE_STORAGE_DIR: Madek::Constants::FILE_STORAGE_DIR,
  THUMBNAIL_STORAGE_DIR: Madek::Constants::THUMBNAIL_STORAGE_DIR
}.freeze

module Concerns
  module AppEnvironmentInfo
    extend ActiveSupport::Concern

    private

    def app_environment_info
      {
        madek: get_madek_base_info,
        storage: get_file_storage_info,
        ruby: { version: RUBY_VERSION, platform: RUBY_PLATFORM },
        rails: Rails.version,
        postgres: get_pg_version,
        system: read_system_info_for_rails
      }
    end

    # helpers

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

    def get_file_storage_info(file_stores = MADEK_FILE_STORES)
      stores = file_stores.map { |k, v| [k, v.to_s] }.to_h

      mounts = begin
        stores.map { |k, v| [v, Sys::Filesystem.mount_point(v)] }.to_h
      rescue => err; err; end

      stats = begin
        mounts.values.uniq.map { |m| [m, Sys::Filesystem.stat(m)] }.to_h
      rescue => err; err; end

      mountpoints = begin
        Sys::Filesystem.mounts.group_by(&:mount_point)
      rescue => err; err; end

      {
        stores: stores,
        mounts_by_path: mounts,
        stats_by_mount: stats,
        mountpoints: mountpoints
      }.as_json
    end

    def get_pg_version
      ActiveRecord::Base.connection.execute('SELECT version();').to_a.first
    end

  end
end
