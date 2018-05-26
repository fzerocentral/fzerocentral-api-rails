Rails.application.routes.draw do
  resources :charts
  resources :leaf_chart_groups
  resources :chart_groups
  resources :games
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
