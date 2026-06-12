Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resource :registration, only: [ :new, :create ]
  resource :theme, only: :update

  root "dashboard#show"

  resources :people do
    collection do
      get :import
      post :import
    end
    resources :notes, only: :create
  end
  resources :segments

  resources :conversations, only: [ :index, :show ], path: "inbox" do
    member do
      post :reply
    end
  end
  resources :blasts do
    member do
      post :send_now
      post :schedule
      post :cancel
      post :clone
      post :test_send
    end
  end
  resources :sms_templates, except: :show
  resources :email_templates, except: :show
  resources :email_blasts do
    member do
      post :send_now
      post :schedule
      post :cancel
    end
  end
  resources :workflows do
    member do
      post :toggle
    end
  end
  resources :workflow_runs, only: :destroy
  get "l/:token", to: "short_links#show", as: :short_link
  get "unsubscribe/:token", to: "email_tracking#unsubscribe", as: :unsubscribe
  get "email/open/:token", to: "email_tracking#open", as: :email_open
  resources :keywords, only: [ :index, :create, :destroy ]

  resources :events do
    member do
      post :check_in
      post :clone
      post :approve
    end
    collection do
      post :redeem_cohost
    end
    resources :event_sessions, only: [ :create, :destroy ], shallow: true
  end
  get "host/:token", to: "host_tools#show", as: :host_tools
  post "host/:token/check_in/:rsvp_id", to: "host_tools#check_in", as: :host_tools_check_in
  get "rsvp/confirm/:token", to: "rsvp_confirmations#show", as: :rsvp_confirmation
  get "calendar/:org_slug", to: "public/calendars#feed", as: :calendar_feed, defaults: { format: "ics" }

  resources :forms

  scope "o/:org_slug", module: :public, as: :public do
    resources :events, only: [ :index, :show ] do
      member do
        post :rsvp
        get :calendar, defaults: { format: "ics" }
      end
    end
    get "host-an-event", to: "event_submissions#new", as: :host_an_event
    post "host-an-event", to: "event_submissions#create"
    get "f/:slug", to: "forms#show", as: :form
    post "f/:slug", to: "forms#submit", as: :submit_form
  end

  resources :donations, only: [ :index, :new, :create ]

  namespace :webhooks do
    post "twilio/inbound_sms", to: "twilio#inbound_sms"
    post "twilio/sms_status", to: "twilio#sms_status"
    post "donations/:token", to: "donations#create", as: :donations
    post "attendance/:token", to: "attendance#create", as: :attendance
  end

  namespace :settings do
    resource :organization, only: [ :show, :update ]
    resources :chapters
    resources :members, only: [ :index, :new, :create, :destroy ]
    resources :custom_fields, only: [ :index, :create, :destroy ]
  end
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
