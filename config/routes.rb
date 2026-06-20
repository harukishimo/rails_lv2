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
    resource :evaluation_target_import, only: :new, controller: :evaluation_target_imports do
      post :preview
      post :import, action: :create
    end
    get "exports", to: "exports#show", as: :exports
    get "exports/:report(.:format)", to: "exports#download", as: :export
  end

  resources :exam_applications, only: %i[index show new create] do
    resource :interview_application, only: %i[new create]
    resources :review_applications, only: %i[new create], shallow: true do
      patch :cancel, on: :member
    end
  end
  resources :evaluation_targets, only: :index
  resources :user_qualifications, only: :index
  namespace :examiner do
    resources :review_queue, only: :index
    resources :candidates, only: %i[index show]
  end
  resources :interview_applications, only: :show do
    member do
      get :assignment
      patch :assignment, action: :assign
    end
    resources :interview_schedules, only: :create
    resource :interview_result, only: :create
  end
  resources :interview_schedules, only: [] do
    patch :approve, on: :member
    patch :reject, on: :member
  end
  resources :review_applications, only: %i[show edit update] do
    resources :review_comments, only: :create
    resources :review_decisions, only: :create
  end
  resources :review_comments, only: :update

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
