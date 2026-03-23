class User < ApplicationRecord
  OmniAuthResult = Struct.new(:user, :error, keyword_init: true)

  has_many :game_sessions, dependent: :nullify
  has_many :user_identities, dependent: :destroy

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :omniauthable,
         omniauth_providers: %i[google_oauth2 github]

  def self.from_omniauth(auth)
    identity = UserIdentity.find_by(provider: auth.provider, uid: auth.uid)
    return OmniAuthResult.new(user: identity.user) if identity

    email = auth.info.email.to_s.strip.downcase
    return OmniAuthResult.new(error: "Your #{provider_label(auth.provider)} account did not provide an email address.") if email.blank?
    return OmniAuthResult.new(error: "Google did not provide a verified email address.") if unverified_google_email?(auth)

    user = User.find_or_initialize_by(email: email)
    if user.new_record?
      generated_password = Devise.friendly_token.first(32)
      user.password = generated_password
      user.password_confirmation = generated_password
      user.save!
    end

    linked_identity = user.user_identities.find_by(provider: auth.provider)
    if linked_identity.present? && linked_identity.uid != auth.uid
      return OmniAuthResult.new(error: "This account is already linked to a different #{provider_label(auth.provider)} profile.")
    end

    linked_identity ||= user.user_identities.new(provider: auth.provider)
    linked_identity.uid = auth.uid
    linked_identity.email = email
    linked_identity.save!

    OmniAuthResult.new(user: user)
  rescue ActiveRecord::RecordInvalid => error
    OmniAuthResult.new(error: error.record.errors.full_messages.to_sentence)
  end

  def self.provider_label(provider)
    provider.to_s == "google_oauth2" ? "Google" : provider.to_s.titleize
  end

  def self.unverified_google_email?(auth)
    auth.provider == "google_oauth2" && !ActiveModel::Type::Boolean.new.cast(auth.info.email_verified)
  end

  private_class_method :provider_label, :unverified_google_email?
end
