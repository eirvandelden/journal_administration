# rubocop:disable Metrics/BlockLength
Rails.application.routes.draw do
  resources :category_groups
  resources :categories_groups
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
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  # Clearance routes
  resources :passwords, controller: "clearance/passwords", only: %i[create new]
  resource :session, controller: "clearance/sessions", only: [:create]

  resources :users, controller: "clearance/users", only: [:create] do
    resource :password, controller: "clearance/passwords", only: %i[create edit update]
  end

  get "/sign_in" => "clearance/sessions#new", as: "sign_in"
  delete "/sign_out" => "clearance/sessions#destroy", as: "sign_out"
  get "/sign_up" => "clearance/users#new", as: "sign_up"

  root "dashboard#index"
end
# rubocop:enable Metrics/BlockLength
