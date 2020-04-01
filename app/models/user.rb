class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  has_one :ca, foreign_key: :user_id, dependent: :destroy
  has_many :csrs, foreign_key: :user_id, dependent: :destroy
end
