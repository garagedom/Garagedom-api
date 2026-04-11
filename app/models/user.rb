class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  has_one :profile, dependent: :destroy

  devise :database_authenticatable, :registerable,
         :recoverable, :validatable,
         :omniauthable,
         :jwt_authenticatable, jwt_revocation_strategy: self,
         omniauth_providers: %i[google_oauth2 facebook]

  validates :terms_accepted, acceptance: { message: :terms_required }, on: :create,
            unless: :oauth_user?

  def self.from_omniauth(auth)
    user = find_or_initialize_by(provider: auth.provider, uid: auth.uid)
    user.email = auth.info.email if user.email.blank?
    if user.new_record?
      user.password = SecureRandom.hex(16)
      user.terms_accepted = true
    end
    user.save!
    user
  rescue ActiveRecord::RecordInvalid
    nil
  end

  private

  def oauth_user?
    provider.present?
  end
end
