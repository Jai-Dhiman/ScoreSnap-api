I18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]
I18n.available_locales = [:en]
I18n.default_locale = :en
I18n.fallbacks = I18n::Locale::Fallbacks.new