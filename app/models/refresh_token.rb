class RefreshToken < ApplicationRecord
  belongs_to :user

  EXPIRY = 30.days

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  def self.generate_for(user)
    create!(
      user: user,
      token: SecureRandom.urlsafe_base64(32),
      expires_at: EXPIRY.from_now
    )
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def active?
    revoked_at.nil? && expires_at > Time.current
  end
end
