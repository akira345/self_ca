class Ca < ActiveRecord::Base
  validates :hostname,:presence => true,:uniqueness => {:scope=>:user_id} 
  validates :country,:presence=>true
  validates :dn_st,:presence=>true
  validates :dn_l,:presence=>true
  validates :dn_o,:presence=>true

  belongs_to :user
end
