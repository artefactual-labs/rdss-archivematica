<SPConfig xmlns="urn:mace:shibboleth:2.0:native:sp:config"
    xmlns:conf="urn:mace:shibboleth:2.0:native:sp:config"
    xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
    xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
    xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
    clockSkew="180">
    <RequestMapper type="XML">
        <RequestMap>
          <Host name="${CLIENT_APP_HOSTNAME:-your-app.localdomain.com}"
                scheme="https"
                authType="shibboleth"
                requireSession="true">
              <Path name="${CLIENT_APP_SECURE_PATH:-/app}"/>
          </Host>
        </RequestMap>
    </RequestMapper>
    <ApplicationDefaults entityID="${CLIENT_APP_SCHEME:-https}://${CLIENT_APP_HOSTNAME:-your-app.localdomain.com}${SHIBBOLETH_RESPONDER_PATH:-/saml}/metadata" 
            REMOTE_USER="eppn persistent-id targeted-id">
        <!-- Session config -->
        <Sessions lifetime="28800" timeout="3600" relayState="ss:mem"
                  checkAddress="false"
                  handlerSSL="true"
                  cookieProps="https">
            <SSO entityID="${SHIBBOLETH_IDP_ENTITY_ID:-https://idp.testshib.org/idp/shibboleth}">
                SAML2
            </SSO>
            <Logout>SAML2 Local</Logout>
            <Handler type="MetadataGenerator" Location="/metadata" signing="false"/>
            <Handler type="Status" Location="/status" />
            <Handler type="Session" Location="/session" showAttributeValues="true"/>
            <md:AssertionConsumerService Location="/acs"
               index="1" isDefault="true"
               Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" />
        </Sessions>
        <!-- Metadata config -->
        <MetadataProvider type="XML"
            uri="${SHIBBOLETH_IDP_METADATA_URL:-http://www.testshib.org/metadata/testshib-providers.xml}"
            backingFilePath="idp-metadata.xml"
            minRefreshDelay="10" maxRefreshDelay="5000" refreshDelayFactory="0.1"/>
        <!-- Attributes config -->
        <AttributeExtractor type="XML" validate="true" reloadChanges="false" path="attribute-map.xml"/>
        <AttributeResolver type="Query" subjectMatch="true"/>
        <AttributeFilter type="XML" validate="true" path="attribute-policy.xml"/>
        <!-- Trust credentials config -->
        <CredentialResolver type="File" key="/etc/shibboleth/sp-key.pem">
          <Certificate>
            <Path>/etc/shibboleth/sp-cert.pem</Path>
            <Path>/etc/shibboleth/sp-ca-cert.pem</Path>
          </Certificate>
        </CredentialResolver>
    </ApplicationDefaults>
    <SecurityPolicyProvider type="XML" validate="true" path="security-policy.xml"/>
    <ProtocolProvider type="XML" validate="true" reloadChanges="false" path="protocols.xml"/>
</SPConfig>
