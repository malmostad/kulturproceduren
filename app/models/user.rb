require 'digest/sha1'

class User < ActiveRecord::Base

  has_and_belongs_to_many  :roles
  has_and_belongs_to_many  :groups            #Role CultureAdministrator
  has_and_belongs_to_many  :occasions         #Role Host
  has_and_belongs_to_many  :districts         #Role CultureCoordinator
  has_and_belongs_to_many  :culture_providers #Role CultureWorker
  has_many :role_applications, :order => "updated_at DESC", :include => [ :role ]
  
  validates_presence_of :username, :password, :name, :email, :mobil_nr
  validates_uniqueness_of :username
  validates_confirmation_of :password

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


  def has_role?(role)
    roles.exists? [ "lower(name) = ?", role.to_s.downcase ]
  end

  
  def password=(pass)
    write_password(pass)
  end

  def password_confirmation=(pass)
    write_password(pass, :password_confirmation)
  end

  def reset_password
    self.salt = nil
    write_attribute :password, nil
    write_attribute :password_confirmation, nil
  end

  
  private

  def write_password(pass, attr = :password)
    if pass.length > 0
      self.salt = User.random_string(APP_CONFIG[:salt_length]) unless self.salt
      write_attribute attr, User.encrypt(pass, self.salt)
    end
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
