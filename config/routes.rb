Rails.application.routes.draw do
  mount Appkit::Engine => "/"

  namespace :admin do
    root "dashboard#index"
    resources :users
  end

  resources :chattels
  resources :product_types, except: %i[destroy]
  resources :products, only: %i[index show edit update]
  resources :receipts, only: %i[index show] do
    scope module: "receipts" do
      resource :payment_link, only: %i[create destroy]
    end
  end
  root "dashboard#index"

  resources :users, only: %i[index update destroy] do
    scope module: "users" do
      resource :profile
    end
  end

  resources :transactions do
    resources :transaction_links, only: %i[create destroy index]
    resources :transaction_splits, only: %i[create update destroy]
  end
  namespace :transactions do
    resources :imports, only: %i[new create]
  end
  resources :credit, controller: "transactions", type: "Transaction"
  resources :debit, controller: "transactions", type: "Transaction"
  resources :transfer, controller: "transactions", type: "Transaction"
  resources :accounts do
    scope module: "accounts" do
      resource :transactions_bulk, only: [ :update ]
      resource :transaction_absorption, only: [ :create ]
      resources :account_aliases, only: %i[create destroy]
    end
  end
  resources :budgets do
    resource :suggestion, only: %i[create update], module: :budgets
  end
  resources :categories
  resources :searches, only: [ :index ]
  get "dashboard/index"
  get "todo", to: "todos#index", as: :todo

  match "mcp" => "assistant#create", via: %i[ post get delete ], as: :assistant

  get "up" => "rails/health#show", as: :rails_health_check
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
