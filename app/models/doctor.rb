class Doctor < ActiveRecord::Base
  named_scope :by_name, lambda {|name| {:select => 'DISTINCT doctors.*', :joins => :vcard, :order => 'family_name', :conditions => Vcards::Vcard.by_name_conditions(name)}}

  has_one :vcard, :class_name => 'Vcards::Vcard', :as => 'object'
  has_many :vcards, :class_name => 'Vcards::Vcard', :as => 'object'

  belongs_to :billing_doctor, :class_name => 'Doctor'
  belongs_to :account, :class_name => 'Accounting::Account'

  has_many :mailings
  has_many :patients

  has_and_belongs_to_many :offices

  def to_s
    [vcard.honorific_prefix, vcard.given_name, vcard.family_name].compact.select{|f| not f.empty?}.join(" ")
  end

  # Proxy accessors
  def name
    if vcard.nil?
      login
    else
      vcard.full_name
    end
  end

  def colleagues
    offices.map{|o| o.doctors}.flatten.uniq
  end

  # TODO:
  # This is kind of a primary office providing printers etc.
  # But it undermines the assumption that a doctor may belong/
  # own more than one office.
  def office
    offices.first
  end

  # ZSR sanitation
  def zsr=(value)
    value.delete!(' .') unless value.nil?
    
    write_attribute(:zsr, value)
  end

  # Search
  def self.clever_find(query)
    return [] if query.nil? or query.empty?
    
    query_params = {}
    query_params[:query] = "%#{query}%"

    vcard_condition = "(vcards.given_name LIKE :query) OR (vcards.family_name LIKE :query) OR (vcards.full_name LIKE :query)"

    find(:all, :include => [:vcard], :conditions => ["#{vcard_condition}", query_params], :order => 'full_name, family_name, given_name')
  end
end
