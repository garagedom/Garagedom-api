Rails.application.routes.draw do
  devise_for :users,
    path: "",
    path_names: {
      sign_in: "api/v1/auth/login",
      sign_out: "api/v1/auth/logout",
      registration: "api/v1/auth/register",
      password: "api/v1/auth/password"
    },
    controllers: {
      sessions: "api/v1/sessions",
      registrations: "api/v1/registrations",
      passwords: "api/v1/passwords",
      omniauth_callbacks: "api/v1/omniauth_callbacks"
    }

  namespace :api do
    namespace :v1 do
      delete "account", to: "accounts#destroy"
      resources :profiles, only: [ :create, :show, :update ]
      get "map/pins", to: "map#pins"
    end
  end

  mount ActionCable.server => "/cable"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
