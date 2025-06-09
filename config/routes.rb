Rails.application.routes.draw do
  root "dashboard#index"

  resource :session, only: %i[ new create destroy ] do
    scope module: "sessions" do
      resources :transfers, only: %i[ show update ]
    end
  end

  resources :users do
    scope module: "users" do
      resource :profile
    end
  end

  resources :transactions do
    collection do
      post :upload
    end
  end
  resources :credit, controller: "transactions", type: "Transaction"
  resources :debit, controller: "transactions", type: "Transaction"
  resources :transfer, controller: "transactions", type: "Transaction"
  resources :accounts do
    member do
      get :update_transactions
    end
  end
  resources :categories
  get "dashboard/index"

  get "up" => "rails/health#show", as: :rails_health_check
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
