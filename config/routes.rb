Rails.application.routes.draw do
  scope PluginRoutes.system_info['relative_url_root'], as: 'cama' do
    # root "application#index"
    default_url_options PluginRoutes.default_url_options

    # public
    get 'error', as: 'error', to: 'camaleon_cms/camaleon#render_error'
    get 'captcha', as: 'captcha', to: 'camaleon_cms/camaleon#captcha'
    eval(PluginRoutes.load('main'))
  end

  namespace :api do
    namespace :cms do
      namespace :v1 do
        resources :post_types, only: [:show, :index], param: :slug
        resources :posts, only: [:index, :show], param: :slug do
          resources :comments, only: [:create]
        end
        get 'sitemap', to: 'sitemap#show'
      end
    end
  end
end
