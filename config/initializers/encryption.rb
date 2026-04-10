# Active Record Encryption — configured via Rails credentials or environment variables
#
# To set up:
#   1. Run: bin/rails db:encryption:init
#   2. Add generated keys to credentials: bin/rails credentials:edit
#      active_record_encryption:
#        primary_key: <generated>
#        deterministic_key: <generated>
#        key_derivation_salt: <generated>
#
# Usage in models:
#   encrypts :body  (see Message model — Story 5.x)
#
# Keys are automatically picked up by Rails from credentials.yml.enc.
# In non-credential environments, set environment variables:
#   ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY
#   ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY
#   ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT
