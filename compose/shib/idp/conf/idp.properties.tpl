
# Required params
idp.scope=${IDP_DOMAIN}
idp.entityID=https://${IDP_HOSTNAME}/idp/shibboleth
idp.ldap.basedn=${IDP_DOMAIN_BASEDN}
idp.ldap.host=${IDP_LDAP_HOSTNAME}
idp.sealer.keyPassword=12345
idp.sealer.storePassword=12345

# Relax requirement for authn request to be encrypted (for testing only)
idp.encryption.optional = true

# Enable detailed error messages sent back to SP
idp.errors.detailed = true

# Enable Single Log Out (SLO)
idp.logout.authenticated = true
idp.logout.elaboration = true
idp.session.enabled = true
idp.session.secondaryServiceIndex = true
idp.session.trackSPSessions = true
idp.storage.htmlLocalStorage = true
