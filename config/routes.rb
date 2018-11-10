Rails.application.routes.draw do
  resources :filters
  resources :filter_groups
  resources :chart_types
  resources :charts
  resources :chart_groups
  resources :games
  resources :records
  resources :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
