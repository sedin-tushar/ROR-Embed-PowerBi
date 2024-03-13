Rails.application.routes.draw do
  root 'analytics#index', as: 'index'

  get '/load-embed-config', to: 'analytics#load_embed_config'
end
