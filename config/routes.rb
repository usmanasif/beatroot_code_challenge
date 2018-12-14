Rails.application.routes.draw do
  resources :releases, only: [:index] do
    member do
      get :download
    end
  end
end
