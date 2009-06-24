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
  map.resources :events, :except => [ :index ]
  map.resources :occasions, :except => [ :index ]
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

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => "calendar"
  map.delquest 'questionaires/:questionaire_id/destroy/:question_id' , :controller => "questions" , :action => "destroy"
  #Not so RESTful ....
  map.ansquest 'questionaires/:answer_form_id/answer' , :controller => 'answer_form' , :action => 'show'
  map.attlist 'occasions/:id/attlist' , :controller => 'occasions' , :action => 'attlist'
  map.eventstat 'events/:id/statistics' , :controller => "events" , :action => "stats"
  map.attlist_pdf 'occasions/:id/attlist_pdf' , :controller => 'occasions' , :action => 'attlist_pdf'
  map.question_graph 'questions/:question_id/graph/:occasion_id' , :controller => 'questions' , :action => 'stat_graph'

  map.new_cp_img 'culture_providers/:culture_provider_id/images/new', :controller => 'images', :action => 'new', :type => :normal
  map.new_cp_main_img 'culture_providers/:culture_provider_id/images/new/main', :controller => 'images', :action => 'new', :type => :main
  map.new_ev_img 'events/:event_id/images/new', :controller => 'images', :action => 'new', :type => :normal
  map.new_ev_main_img 'events/:event_id/images/new/main', :controller => 'images', :action => 'new', :type => :main

  map.grant_role 'users/:id/grant/:role', :controller => 'users', :action => 'grant'
  map.revoke_role 'users/:id/revoke/:role', :controller => 'users', :action => 'revoke'
  map.remove_culture_provider_user 'users/:id/remove_culture_provider/:culture_provider_id', :controller => 'users', :action => 'remove_culture_provider'

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
