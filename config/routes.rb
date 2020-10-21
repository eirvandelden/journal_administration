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

  root "dashboard#index"
end
