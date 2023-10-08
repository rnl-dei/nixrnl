{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [./common.nix];

  age.secrets."papyrus-private.env" = {
    file = ../../secrets/papyrus-private-env.age;
  };

  services.mattermost = {
    package = pkgs.unstable.mattermost; # Version >7.10
    environmentFile = config.age.secrets."papyrus-private.env".path;

    # Reference: https://docs.mattermost.com/configure/configuration-settings.html
    extraConfig = {
      ServiceSettings = {
        EnableBotAccountCreation = true;
        EnablePostUsernameOverride = true;
        EnablePostIconOverride = true;
      };
      TeamSettings = {
        CustomBrandText = "Welcome to RNL!";
        MaxUsersPerTeam = 100;
      };
      SqlSettings = {
        DriverName = "mysql";
        # Set DataSource through environment variable
      };
      EmailSettings = {
        EnableSignUpWithEmail = true;
        EnableSignInWithEmail = true;
        EnableSignInWithUsername = true;
        SendEmailNotifications = true;
        UseChannelInEmailNotifications = true;
        RequireEmailVerification = true;
        FeedbackName = "Mattermost @ RNL";
        FeedbackEmail = "mattermost@${config.networking.fqdn}";
        ReplyToAddress = "noreply@${config.rnl.domain}";
        SMTPServer = config.rnl.mailserver.host;
        SMTPPort = toString config.rnl.mailserver.port;
      };
    };

    plugins = with pkgs.mattermostPlugins; [playbooks rssfeed];
  };
}
