class Csr < ApplicationRecord
  validates :hostname, presence: true, uniqueness: { scope: :user_id }, length: { maximum: 256 }
  validates :country, presence: true, length: { maximum: 20 }
  validates :dn_st, presence: true, length:  { maximum: 20 }
  validates :dn_l, presence: true, length:  { maximum: 20 }
  validates :dn_o, presence: true, length: { maximum: 20 }
  validates_format_of :hostname, with: /\A[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}\z/ix
  validates_format_of :dn_st, with: /\A[a-z0-9]+\z/i
  validates_format_of :dn_l, with: /\A[a-z0-9]+\z/i
  validates_format_of :dn_o, with: /\A[a-z0-9]+\z/i

  belongs_to :user
end
