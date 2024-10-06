Rails.application.routes.draw do
  namespace :api do
    resources :images, only: [] do
      collection do
        post 'upload'
        post 'process_image'
      end
    end
    
    resources :scores, only: [:index, :show, :update, :destroy] do
      member do
        get 'download'
      end
    end

    resources :users, only: [:create]
    post "/sessions" => "sessions#create"
  end

  get "up" => "rails/health#show", as: :rails_health_check

end