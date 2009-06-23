require 'digest/sha1'
require "pp"

class User < ActiveRecord::Base

  has_and_belongs_to_many  :roles
  has_and_belongs_to_many  :culture_providers
  has_many :role_applications, :order => "updated_at DESC", :include => [ :role ]

  has_many :tickets
  has_many :occasions , :through => :tickets , :uniq => true
  has_many :notification_requests
  
  validates_presence_of :username, :message => "Användarnamnet får inte vara tomt"
  validates_presence_of :password, :message => "Lösenordet får inte vara tomt"
  validates_presence_of :name, :message => "Namnet får inte vara tomt"
  validates_presence_of :email, :message => "Epostadressen får inte vara tom"
  validates_presence_of :mobil_nr, :message => "Mobilnumret får inte vara tomt"
  validates_uniqueness_of :username, :message => "Användarnamnet är redan taget"
  validates_confirmation_of :password, :message => "Lösenordsbekräftelsen matchar inte lösenordet"

  attr_protected :id, :salt


  def authenticate(password)
    User.encrypt(password, self.salt) == self.password
  end

  def self.authenticate(username, password)
    u = find :first, :conditions => { :username => username }
    
    return nil if u.nil?
    return u if u.authenticate(password)
    
    nil
  end

  def bookings
    ret = []
    self.occasions.each do |o|
      Ticket.find(:all , :select => "distinct group_id" , :conditions => { :user_id => self.id , :occasion_id => o.id}).each do |t|
        ret << { "occasion" => o , "group" => Group.find(t.group_id) }
      end
    end
    return ret
  end

  def has_role?(*rs)
    rs.each do |r|
      return true if roles.exists? [ "lower(name) = ?", r.to_s.downcase ]
    end
    return false
  end

  def can_administrate?(e)
    case e
    when CultureProvider
      return has_role?(:admin) || (has_role?(:culture_worker) && culture_providers.include?(e))
    else
      return false
    end
  end

  def can_book?
    return has_role?(:admin, :booker)
  end

  
  def password=(pass)
    if pass.length > 0
      self.salt = User.random_string(APP_CONFIG[:salt_length]) unless self.salt
      write_attribute :password, User.encrypt(pass, self.salt)
    end
  end

  def password_confirmation=(pass)
    self.salt = User.random_string(APP_CONFIG[:salt_length]) unless self.salt
    @password_confirmation = User.encrypt(pass, self.salt)
  end

  def reset_password
    self.salt = nil
    write_attribute :password, nil
    write_attribute :password_confirmation, nil
  end

  
  private

  def write_password(pass, attr = :password)

  end
  
  def self.encrypt(pass, salt)
    Digest::SHA1.hexdigest(pass + salt)
  end

  def self.random_string(len)
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a

    newpass = ""
    1.upto(len) { |i| newpass << chars[rand(chars.size - 1)] }
    return newpass
  end

end
