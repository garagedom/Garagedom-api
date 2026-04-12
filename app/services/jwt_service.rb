class JwtService
  def self.decode(token)
    secret = Devise.jwt.secret
    decoded = JWT.decode(token, secret, true, algorithms: [ "HS256" ])
    decoded.first
  rescue JWT::DecodeError
    raise
  end
end
