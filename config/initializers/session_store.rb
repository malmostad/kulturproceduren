# Be sure to restart your server when you modify this file.

Kulturproceduren::Application.config.session_store :active_record_store, key: '_kp_session'

ActiveRecord::SessionStore::Session.attr_accessible :data, :session_id

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Kulturproceduren::Application.config.session_store :active_record_store
