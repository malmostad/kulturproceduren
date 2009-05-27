require 'digest/sha1'

class User < ActiveRecord::Base

  has_and_belongs_to_many  :roles
  has_and_belongs_to_many  :groups            #Role CultureAdministrator
  has_and_belongs_to_many  :occasions         #Role Host
  has_and_belongs_to_many  :districts         #Role CultureCoordinator
  has_and_belongs_to_many  :culture_providers #Role CultureWorker
  
  validates_presence_of :username, :password, :salt, :name, :email, :mobil_nr
  validates_uniqueness_of :username

  attr_protected :id, :salt


  def self.authenticate(username, password)
    u = find :first, :conditions => { :username => username }
    
    return nil if u.nil?
    return u if User.encrypt(password, u.salt) == u.password
    
    nil
  end

  def password=(pass)
    self.salt = User.random_string(APP_CONFIG[:salt_length]) unless self.salt
    write_attribute :password, User.encrypt(pass, self.salt)
  end

  private
  
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
