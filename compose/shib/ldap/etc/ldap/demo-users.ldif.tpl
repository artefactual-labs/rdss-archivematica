dn: OU=physics,${LDAP_BASEDN}
objectClass: top
objectClass: organizationalUnit
objectClass: eduOrg
ou: physics

dn: OU=socsci,${LDAP_BASEDN}
objectClass: top
objectClass: organizationalUnit
objectClass: eduOrg
ou: socsci

dn: CN=Alice Arnold,OU=physics,${LDAP_BASEDN}
objectClass: top
objectClass: person
objectClass: inetOrgPerson
objectClass: eduPerson
cn: Alice Arnold
eduPersonEntitlement: preservation-user
eduPersonPrincipalName: aa
eduPersonScopedAffiliation: staff
eduPersonTargetedID: 92395ca4-2ac5-11e7-8b0f-1779ed21e50b
givenName: Alice
mail: alice.arnold@physics.${LDAP_DOMAIN}
ou: physics
sn: Arnold
userPassword: aa12345

dn: CN=Bert Bellwether,OU=socsci,${LDAP_BASEDN}
objectClass: top
objectClass: person
objectClass: inetOrgPerson
objectClass: eduPerson
cn: Bert Bellwether
eduPersonEntitlement: preservation-administrator
eduPersonPrincipalName: bb
eduPersonScopedAffiliation: staff
eduPersonTargetedID: cb712a42-2ac5-11e7-86a1-9fb67307f507
givenName: Bert
mail: bert.bellwether@socsci.${LDAP_DOMAIN}
ou: socsci
sn: Bellwether
userPassword: bb12345
