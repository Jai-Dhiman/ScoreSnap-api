Rails.application.routes.draw do
  namespace :api do
    post 'images/process', to: 'images#process_image'
  end
end