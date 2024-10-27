require_relative "boot"
require "rails/all"
Bundler.require(*Rails.groups)

module ScoreSnapApi
  class Application < Rails::Application

    config.load_defaults 7.1
    
    config.before_configuration do
      env_file = File.join(Rails.root, 'config', 'local_env.yml')
      if File.exist?(env_file)
        YAML.load(File.open(env_file)).each do |key, value|
          ENV[key.to_s] = value.to_s
        end
      end
      
      ENV['TESSDATA_PREFIX'] = '/usr/local/share/tessdata'
    end

    config.i18n.default_locale = :en
    config.i18n.fallbacks = true
    config.i18n.enforce_available_locales = [:en]
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]
    config.autoload_lib(ignore: %w(assets tasks))
    config.api_only = true
    config.autoload_paths << "#{Rails.root}/app/services"
  end
end