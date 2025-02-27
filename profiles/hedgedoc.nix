{
  environment.etc."hedgedoc.env".text = ''
    CMD_PORT=80
    CMD_DOMAIN=hedgedoc.rnl.tecnico.ulisboa.pt
    CMD_HOST=localhost
  '';
  /**
      hegdedoc oauth stuff
      CMD_OAUTH2_USER_PROFILE_USERNAME_ATTR=username
      CMD_OAUTH2_USER_PROFILE_DISPLAY_NAME_ATTR=displayName
      CMD_OAUTH2_TOKEN_URL=https://fenix.tecnico.ulisboa.pt/oauth/access_token
      CMD_OAUTH2_AUTHORIZATION_URL=https://fenix.tecnico.ulisboa.pt/oauth/userdialog
      CMD_OAUTH2_CLIENT_ID=288540197912778
      CMD_OAUTH2_PROVIDERNAME=Fénix
  */
  #MISSING: CMD_OAUTH2_CLIENT_SECRET=<very secret!>
  services.hedgedoc = {
    enable = true;
    environmentFile = "/etc/hedgedoc.env";
  };
}

/**
  Relevant gitlab config, just for reference
  ### OmniAuth Settings
  ###! Docs: https://docs.gitlab.com/ee/integration/omniauth.html
  gitlab_rails['omniauth_enabled'] = true
  gitlab_rails['omniauth_allow_single_sign_on'] = ['oauth2_generic']
  gitlab_rails['omniauth_sync_email_from_provider'] = 'oauth2_generic'
  gitlab_rails['omniauth_sync_profile_from_provider'] = ['oauth2_generic']
  gitlab_rails['omniauth_sync_profile_attributes'] = ['username', 'name']
  # gitlab_rails['omniauth_auto_sign_in_with_provider'] = 'saml'
  gitlab_rails['omniauth_block_auto_created_users'] = false
  # gitlab_rails['omniauth_auto_link_ldap_user'] = true
  # gitlab_rails['omniauth_auto_link_saml_user'] = false
  gitlab_rails['omniauth_auto_link_user'] = ['oauth2_generic']
  # gitlab_rails['omniauth_external_providers'] = ['twitter', 'google_oauth2']
  # gitlab_rails['omniauth_allow_bypass_two_factor'] = ['google_oauth2']
  gitlab_rails['omniauth_providers'] = [
    {
      name: 'oauth2_generic',
      icon: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAEE0lEQVR4Ae2aA9ArSRCA+2zbtn3Fs23bKp5t23fJRs+2bdvKzuxubF7+qO9mT8HT7h/O26+qS+nUTH+rEWwQgSBXoRlDgCHAE>
      label: 'Técnico ID',
      app_id: '1977390058176856',
      app_secret: 'DudW1df7QgH/QeM8qbvafim8xRZgxAmPSMoPhulzHihEKioURenvpuFgIPhTRWCBQkI5Xe0j+70CXBYFEYP7VQ==',
      args: {
        client_options: {
          site: 'https://fenix.tecnico.ulisboa.pt',
          user_info_url: '/api/fenix/v1/person',
          authorize_url: '/oauth/userdialog',
          token_url: '/oauth/access_token'
        },
        user_response_structure: {
          id_path: 'username',
          attributes: {
            uid: 'username',
            nickname: 'username',
            email: 'institutionalEmail',
            name: 'displayName',
            image: ['photo' 'data']
          }
        },
        strategy_class: "OmniAuth::Strategies::OAuth2Generic"
      }

  *
*/
