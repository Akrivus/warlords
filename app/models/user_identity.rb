class UserIdentity < ApplicationRecord
  belongs_to :user

  validates :provider, presence: true, uniqueness: { scope: :uid }
  validates :uid, presence: true
  validates :email, presence: true
end
