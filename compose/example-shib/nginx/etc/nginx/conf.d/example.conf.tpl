server {

  listen 80;
  listen 443 default ssl;

  ssl_certificate     /etc/shibboleth/sp-web-cert.pem;
  ssl_certificate_key /etc/shibboleth/sp-key.pem;
  ssl_protocols       SSLv3 TLSv1 TLSv1.1 TLSv1.2;
  ssl_ciphers         HIGH:!aNULL:!MD5;
  ssl_session_cache   shared:SSL:10m;
  ssl_session_timeout 10m;

  # server_name is important because it is used by shibboleth for generating SAML URLs
  # Using the catch-all '_' will NOT work.
  server_name ${CLIENT_APP_HOSTNAME:-your-app.localdomain.com};

  # FastCGI authorizer for Auth Request module
  location = /shibauthorizer {
    internal;
    include fastcgi_params;
    include shib_fastcgi_params;
    fastcgi_param  HTTPS on;
    fastcgi_param  SERVER_PORT 443;
    fastcgi_param  SERVER_PROTOCOL https;
    fastcgi_param  X_FORWARDED_PROTO https;
    fastcgi_param  X_FORWARDED_PORT 443;
    fastcgi_pass unix:/tmp/shibauthorizer.sock;
  }

  # FastCGI responder
  location ${SHIBBOLETH_RESPONDER_PATH:-/saml} {
    include fastcgi_params;
    fastcgi_param  HTTPS on;
    fastcgi_param  SERVER_PORT 443;
    fastcgi_param  SERVER_PROTOCOL https;
    fastcgi_param  X_FORWARDED_PROTO https;
    fastcgi_param  X_FORWARDED_PORT 443;
    fastcgi_pass unix:/tmp/shibresponder.sock;
  }

  # Resources for the Shibboleth error pages. This can be customised.
  location /shibboleth-sp {
    alias /etc/shibboleth/;
  }

  # Our application secured by Shibboleth. Not all paths are secured, to allow
  # for static resources etc
  location / {
    proxy_pass ${NGINX_PROXY_DESTINATION:-http://172.17.42.1:8001};

    # Set proxy headers
    proxy_set_header        Accept-Encoding   "";
    proxy_set_header        Host            $host;
    proxy_set_header        X-Real-IP       $remote_addr;
    proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
    
    location ${CLIENT_APP_SECURE_PATH:-/app} {
      include shib_clear_headers;
      
      # TODO Add attributes we're interested in here
      
      # Clear existing headers and enable Shibboleth auth
      more_clear_input_headers 'displayName' 'mail' 'persistent-id';
      shib_request /shibauthorizer;
      
      # Pass on the request to our application
      proxy_pass ${NGINX_PROXY_DESTINATION:-http://172.17.42.1:8001};
    }
  }

}