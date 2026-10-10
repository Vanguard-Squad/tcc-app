Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"

  get    "/login",  to: "sessions#new", as: :login
  post   "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout

  get  "/cadastro", to: "registrations#new", as: :new_registration
  post "/cadastro", to: "registrations#create", as: :registrations

  get  "/cadastro/empresa", to: "registrations/companies#new", as: :new_registration_company
  post "/cadastro/empresa", to: "registrations/companies#create", as: :registration_companies

  get "/auditoria", to: "audit_logs#index", as: :audit_logs

  get "/membros", to: "members#index", as: :members
  patch "/membros/:id/ativacao", to: "members#toggle_active", as: :toggle_active_member

  get  "/membros/secretarias/novo", to: "members/managers#new", as: :new_member_manager
  post "/membros/secretarias",      to: "members/managers#create", as: :member_managers
  get  "/membros/secretarias/:id/editar", to: "members/managers#edit", as: :edit_member_manager
  patch "/membros/secretarias/:id",       to: "members/managers#update", as: :member_manager

  get  "/membros/motoristas/novo", to: "members/drivers#new", as: :new_member_driver
  post "/membros/motoristas",      to: "members/drivers#create", as: :member_drivers
  get  "/membros/motoristas/:id/editar", to: "members/drivers#edit", as: :edit_member_driver
  patch "/membros/motoristas/:id",       to: "members/drivers#update", as: :member_driver

  get  "/membros/alunos/novo", to: "members/students#new", as: :new_member_student
  post "/membros/alunos",      to: "members/students#create", as: :member_students
  get  "/membros/alunos/:id/editar", to: "members/students#edit", as: :edit_member_student
  patch "/membros/alunos/:id",       to: "members/students#update", as: :member_student

  resources :vehicles, path: "frota", only: %i[index new create edit update]
  resources :routes, path: "rotas", only: %i[index new create edit update]

  namespace :drivers, path: "motorista" do
    resource :route, path: "rota", only: %i[show edit update] do
      member { get :passengers, path: "passageiros" }
    end
    resource :trip, path: "viagem", only: %i[create destroy]
    resource :trip_position, path: "viagem/posicao", only: :create
    resource :trip_qr_code, path: "viagem/qrcode", only: :show
  end

  namespace :students, path: "aluno" do
    resource :trip, path: "", only: :show
    resources :checkins, only: :create
    resource :qr_checkin, path: "checkin/qr", only: %i[show create]
  end
end
