Kulturproceduren::Application.routes.draw do
  mount JasmineRails::Engine => '/specs' if defined?(JasmineRails)

  resources :users do
    collection do
      post :apply_filter
      get  :request_password_reset
      post :send_password_reset_confirmation
    end
    member do
      get   :edit_password
      patch :update_password
      post  :add_culture_provider
      get   :reset_password
    end

  end

  resources :statistics, only: [:index] do
    member do
      get :visitors
      get :questionnaires
      get :unbooking_questionnaires
    end
  end

  resources :culture_providers do
    member do
      post :deactivate
      post :activate
    end
    resources :images, except: [:show, :edit, :update, :new] do
      member do
        get :set_main
      end
    end
    resources :culture_provider_links, except: [:create, :edit, :update] do
      member do
        get :select
      end
    end

    resources :event_links, except: [:create, :edit, :update] do
      collection do
        post :select_culture_provider
      end
      member do
        get :select_event
      end
    end
  end

  resources :events, except: [:index] do
    collection do
      get :options_list
    end
    member do
      get :ticket_allotment
      get :transition
      patch :next_transition
    end

    resources :occasions,             only: [:index]
    resources :images,                except: [:show, :edit, :update, :new]
    resources :attachments,           except: [:edit, :update, :new]
    resources :notification_requests, only: [:new, :create] do
      collection do
        get :get_input_area
      end
    end
    resources :statistics, only: [:index] do
      member do
        get :visitors
        get :questionnaires
      end
    end
    resources :culture_provider_links, except: [:create, :edit, :update] do
      member do
        get :select
      end
    end
    resources :event_links, except: [:create, :edit, :update] do
      collection do
        post :select_culture_provider
      end
      member do
        get :select_event
      end
    end
    resources :attendance, only: [:index] do
      collection do
        post :update_report
        get  :report
      end
    end
    resources :bookings, only: [:index, :new] do
      collection do
        post :apply_filter
        get  :bus
      end
    end

    resource :information, only: [:new, :create]
  end

  resources :occasions, except: [:index] do
    member do
      get :cancel
      get :ticket_availability
    end

    resources :bookings do
      collection do
        post :apply_filter
      end
    end
    resources :attendance, only: [:index] do
      collection do
        post :update_report
        get :report
      end
    end
    resources :schools, only: [] do
      collection do
        get :search
        post :search
      end
    end
  end

  resources :bookings, except: [:new] do
    collection do
      get :group_list
      get :group
      get :form
      post :apply_filter
    end
    member do
      get :unbook
    end
  end

  resources :questionnaires do
    collection do
      get :unbooking
    end
    member do
      delete :remove_template_question
      post :add_template_question
    end
    resources :questions, except: [:show, :new]
  end

  resources :answers
  resources :questions,       except: [:show, :new]
  resources :categories,      except: [:show, :new]
  resources :category_groups, except: [:show, :new]

  resources :versions, only: [] do
    member do
      put :revert
    end
  end

  resources :districts do
    member do
      get :history
    end
    collection do
      get  :select
      post :select
    end
  end

  resources :schools do
    member do
      get :history
    end
    collection do
      get  :select
      post :select
      get  :search
      post :search
      get  :options_list
    end
  end

  resources :groups do
    member do
      get :history
    end
    collection do
      get  :select
      post :select
      get  :options_list
    end
    member do
      get :move_first_in_priority
      get :move_last_in_priority
    end

  end

  resources :age_groups, except: [:show, :index, :new]
  resources :role_applications, except: [:new] do
    collection do
      get :archive
    end
  end

  resource :information, only: [:new, :create]

  root to: "calendar#index"

  match "calendar/:action/:list" => "calendar#index", as: :calendar, via: [:get, :post]
  match "questionnaires/:answer_form_id/answer" => "answer_form#submit", as: :answer_questionnaire, via: [:get, :post]
  match "users/:id/grant/:role" => "users#grant", as: :grant_role, via: [:get, :post]
  match "users/:id/revoke/:role" => "users#revoke", as: :revoke_role, via: [:get, :post]
  match "users/:id/remove_culture_provider/:culture_provider_id" => "users#remove_culture_provider", as: :remove_culture_provider_user, via: [:get, :post]
  match "/:controller(/:action(/:id))", via: [:get, :post]
end
