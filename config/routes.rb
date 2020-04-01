Rails.application.routes.draw do
  devise_for :users, :controllers => {
    :sessions => 'users/sessions',
    :registrations => 'users/registrations'
  }
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  get 'csrs/download'
  get 'cas/download'
  get 'home/index'
  get 'cas', to: 'cas#index', as: :user_root
  root 'home#index'

  # resourcesで書くと、基本的なルーティング(index,create,new,edit,show,update,destroy)とヘルパーを自動生成してくれる
  resources :cas
  resources :csrs do
    member do
      get :download
    end
  end
end
