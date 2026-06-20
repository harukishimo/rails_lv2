Rails.application.routes.draw do
  devise_for :users

  namespace :api do
    namespace :v1 do
      post "auth/login", to: "auth#login"
      post "auth/refresh", to: "auth#refresh"
      delete "auth/logout", to: "auth#logout"
      get "auth/me", to: "auth#me"
    end
  end

  namespace :admin do
    resource :dashboard, only: :show, controller: :dashboard
  end

  resources :exam_applications, only: %i[index show new create] do
    resources :review_applications, only: %i[new create], shallow: true do
      patch :cancel, on: :member
    end
  end
  resources :review_applications, only: %i[show edit update]

  root "health#index"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
