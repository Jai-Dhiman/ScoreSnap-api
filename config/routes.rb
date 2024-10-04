Rails.application.routes.draw do
  namespace :api do
    resources :images, only: [] do
      collection do
        post 'upload'
        post 'process_image'
      end
    end
    
    resources :scores, only: [:index, :show, :update, :destroy]
  end

  get "up" => "rails/health#show", as: :rails_health_check
end