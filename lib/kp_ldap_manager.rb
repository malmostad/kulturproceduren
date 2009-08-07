require 'ldap'
require 'pp'

class KPLdapManager
  attr_accessor :max_results

  def initialize(address, port, base_dn, bind_dn, bind_password)
    @address = address
    @port = port
    @base_dn = base_dn
    @bind_dn = bind_dn
    @bind_password = bind_password
    @max_results = 0
  end

  def authenticate(username, password)
    connection.bind("uid=#{e(username)},#{@base_dn}", password) { |conn| }
    return username
  rescue LDAP::ResultError
    return nil
  end

  def get_user(username)
    ldapdata = nil

    connection.bind(@bind_dn, @bind_password) do |conn|
      conn.search(
        @base_dn,
        LDAP::LDAP_SCOPE_SUBTREE,
        "(&(objectClass=inetOrgPerson)(uid=#{e(username)}))",
        [ "cn", "mail", "uid" ]
      ) do |entry|
        ldapdata = entry.to_hash
        break
      end
    end

    return ldapdata.nil? ? nil : entry_to_result(ldapdata)
  end

  def search(params)
    conditions = []

    conditions << "(uid=*#{e(params[:username])}*)" if !params[:username].nil? && !params[:username].empty?
    conditions << "(cn=*#{e(params[:name])}*)" if !params[:name].nil? && !params[:name].empty?
    conditions << "(mail=*#{e(params[:email])}*)" if !params[:email].nil? && !params[:email].empty?

    return [] if conditions.empty?

    query = conditions[0]
    1.upto(conditions.length - 1) { |i| query = "(&#{query}#{conditions[i]})" }

    result = []

    connection.bind(@bind_dn, @bind_password) do |conn|
      conn.search(
        @base_dn,
        LDAP::LDAP_SCOPE_SUBTREE,
        query,
        [ "cn", "mail", "uid" ],
        false, 0, 0, "cn"
      ) do |entry|
        result << entry_to_result(entry.to_hash)
      end
    end

    return result
  end

  def self.escape(str)
    str.gsub(/([\\()*\x00])/, "\\\\\\1")
  end


  private

  def connection
    conn = LDAP::Conn.new(@address, @port)
    conn.set_option(LDAP::LDAP_OPT_SIZELIMIT, @max_results) if @max_results > 0
    return conn
  end

  def e(str)
    KPLdapManager.escape(str)
  end

  def entry_to_result(entry)
    return {
      :name => entry["cn"].join(' '),
      :email => entry["mail"].join(' '),
      :cellphone => "0",
      :username => entry["uid"].join(' ')
    }
  end

end
