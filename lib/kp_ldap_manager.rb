require 'ldap'

# Model responsible for managing the LDAP connection from the application
#
# The search methods in this class all return the same result structure,
# a hash with the following keys:
#
# [+:name+] The name in the LDAP entry
# [+:email+] The email address in the LDAP entry
# [+:cellphone+] The cellphone number in the LDAP entry
# [+:username+] The username in the LDAP entry
class KPLdapManager
  attr_accessor :max_results

  # Creates a new manager posed to connect using the given arguments.
  def initialize(address, port, base_dn, bind_dn, bind_password)
    @address = address
    @port = port
    @base_dn = base_dn
    @bind_dn = bind_dn
    @bind_password = bind_password
    @max_results = 0
  end

  # Authenticates against the LDAP using the given username and password.
  def authenticate(username, password)
    connection.bind("uid=#{e(username)},#{@base_dn}", password) { |conn| }
    return username
  rescue LDAP::ResultError
    return nil
  end

  # Fetches details of the user with the given username from the LDAP.
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

  # Searches the LDAP for matches to the parameters.
  #
  # Parameters:
  #
  # [+:username+] adds a filter for the username
  # [+:name+] adds a filter for the name
  # [+:mail+] adds a filter for the email address
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

  # Escapes a search conditions
  def self.escape(str)
    str.gsub(/([\\()*\x00])/, "\\\\\\1")
  end


  private

  # Creates a new connection using the initialization parameters
  def connection
    conn = LDAP::Conn.new(@address, @port)
    conn.set_option(LDAP::LDAP_OPT_SIZELIMIT, @max_results) if @max_results > 0
    return conn
  end

  # Shorthand convenience method for escaping search conditions
  def e(str)
    KPLdapManager.escape(str)
  end

  # Creates a result has from an entry returned from an LDAP query.
  def entry_to_result(entry)
    return {
      :name => entry["cn"].join(' '),
      :email => entry["mail"].join(' '),
      :cellphone => "0",
      :username => entry["uid"].join(' ')
    }
  end

end
