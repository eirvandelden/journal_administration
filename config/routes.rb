Rails.application.routes.draw do
  resources :transactions do
    collection do
      post :upload
    end
  end
  resources :credit, controller: 'transactions', type: 'Transaction'
  resources :debit, controller: 'transactions', type: 'Transaction'
  resources :transfer, controller: 'transactions', type: 'Transaction'
  resources :accounts
  resources :categories
  get 'dashboard/index'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  root 'dashboard#index'
end
