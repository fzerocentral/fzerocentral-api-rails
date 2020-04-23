Rails.application.routes.draw do
  resources :ladders
  resources :filters
  resources :filter_groups
  resources :filter_implications
  resources :filter_implication_links
  resources :chart_types
  resources :chart_type_filter_groups
  resources :charts
  resources :chart_groups
  resources :games
  resources :records
  resources :users
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
