class LdapController < ApplicationController
  layout "admin"

  before_filter :authenticate
  before_filter :require_admin

  def index
  end

  def search
    ldap = get_ldap()
    ldap.max_results = APP_CONFIG[:ldap][:max_search_results] + 1

    @result = ldap.search(params[:ldapquery])

    if @result.empty?
      flash.now[:warning] = "Inga träffar hittades."
    elsif @result.length > APP_CONFIG[:ldap][:max_search_results]
      flash.now[:warning] = "Sökningen resulterade i för många träffar. Var god begränsa sökningen nedan."
      @result.delete_at(@result.length - 1)
    end
  end

  def handle
    ldap = get_ldap()
    user = User.find :first, :conditions => { :username => params[:username] }

    unless user
      ldap_user = ldap.get_user(params[:username])

      user = User.new do |u|
        u.name = ldap_user[:name]
        u.email = ldap_user[:email]
        u.cellphone = ldap_user[:cellphone]
        u.username = ldap_user[:username]
        u.password = "ldap"
      end

      user.save!
    end

    redirect_to user
  end

  private

  def get_ldap
    return KPLdapManager.new APP_CONFIG[:ldap][:address],
      APP_CONFIG[:ldap][:port],
      APP_CONFIG[:ldap][:base_dn],
      APP_CONFIG[:ldap][:bind][:dn],
      APP_CONFIG[:ldap][:bind][:password]
  end
end
