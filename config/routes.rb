ActionController::Routing::Routes.draw do |map|

  map.resources :users,
    :member => {
    :edit_password => :get,
    :update_password => :put,
    :add_culture_provider => :post
  }
  map.resources :images, :only => [ :create, :destroy ]
  map.resources :culture_providers
  map.resources :answers
  map.resources :questions, :except => [ :show, :new ]
  map.resources :questionaires, :member => {
    :add_template_question => :post,
    :remove_template_question => :delete
  } do |questionaire|
    questionaire.resources :questions, :except => [ :show, :new ]
  end
  map.resources :tags
  map.resources :events, :except => [ :index ],
    :member => { :stats => :get }
  map.resources :occasions, :except => [ :index ],
    :member => { :attlist => :get, :attlist_pdf => :get }
  map.resources :notification_requests
  map.resources :categories, :except => [ :show, :new ]
  map.resources :category_groups, :except => [:show, :new ]
  map.resources :booking_requirements
  map.resources :districts
  map.resources :schools,
    :collection => { :options_list => :get }
  map.resources :groups,
    :collection => { :options_list => :get }
  map.resources :age_groups, :except => [ :show, :index, :new ]
  map.resources :role_applications,
    :except => [ :new ],
    :new => { :booker => :get, :culture_worker => :get },
    :collection => { :archive => :get }


  map.root :controller => "calendar"

  map.delquest 'questionaires/:questionaire_id/destroy/:question_id' , :controller => "questions" , :action => "destroy"
  map.ansquest 'questionaires/:answer_form_id/answer' , :controller => 'answer_form' , :action => 'show'
  map.question_graph 'questions/:question_id/graph/:occasion_id' , :controller => 'questions' , :action => 'stat_graph'

  map.new_cp_img 'culture_providers/:culture_provider_id/images/new', :controller => 'images', :action => 'new', :type => :normal
  map.new_cp_main_img 'culture_providers/:culture_provider_id/images/new/main', :controller => 'images', :action => 'new', :type => :main
  map.new_ev_img 'events/:event_id/images/new', :controller => 'images', :action => 'new', :type => :normal
  map.new_ev_main_img 'events/:event_id/images/new/main', :controller => 'images', :action => 'new', :type => :main

  map.grant_role 'users/:id/grant/:role', :controller => 'users', :action => 'grant'
  map.revoke_role 'users/:id/revoke/:role', :controller => 'users', :action => 'revoke'
  map.remove_culture_provider_user 'users/:id/remove_culture_provider/:culture_provider_id', :controller => 'users', :action => 'remove_culture_provider'

  
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
