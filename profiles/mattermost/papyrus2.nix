{ config, pkgs, ... }:
{
  imports = [ ./common.nix ];

  age.secrets."papyrus2-private.env" = {
    file = ../../secrets/papyrus2-private-env.age;
  };

  services.mattermost = {
    environmentFile = config.age.secrets."papyrus2-private.env".path;
    database.fromEnvironment = true;
    # Reference: https://docs.mattermost.com/configure/configuration-settings.html
    settings = {
      ServiceSettings = {
        EnableBotAccountCreation = true;
        EnablePostUsernameOverride = true;
        EnablePostIconOverride = true;
        EnableEmailInvitations = true;
      };
      TeamSettings = {
        CustomBrandText = "Welcome to RNL!";
        MaxUsersPerTeam = 100;
      };
      SqlSettings = {
        DriverName = "postgres";
        # Set DataSource through environment variable
      };
      EmailSettings = {
        EnableSignUpWithEmail = true;
        EnableSignInWithEmail = true;
        EnableSignInWithUsername = true;
        SendEmailNotifications = true;
        UseChannelInEmailNotifications = true;
        RequireEmailVerification = true;
        FeedbackName = "Mattermost @ RNL (teste)";
        FeedbackEmail = "mattermost@${config.networking.fqdn}";
        ReplyToAddress = "noreply@${config.rnl.domain}";
        SMTPServer = config.rnl.mailserver.host;
        SMTPPort = toString config.rnl.mailserver.port;
      };
    };

    plugins = with pkgs.mattermostPlugins; [
      playbooks
      rssfeed
    ];
  };
}
