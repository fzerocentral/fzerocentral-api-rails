Rails.application.routes.draw do
  resources :charts
  resources :chart_groups
  resources :games
  resources :records
  resources :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
