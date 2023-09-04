{
  config,
  pkgs,
  ...
}: {
  services.dokuwiki.sites."wiki" = {
    enable = true;
    settings = {
      # Basic
      title = "RNL Wiki";
      tagline = "Rosmaninho Natural e Laranjas";
      template = "bootstrap3";
      license = "";
      # Display
      recent = 200;
      recent_days = 365;
      signature = "";
      useheading = "1";
      # Authentication
      useacl = true;
      passcrypt = "argon2id";
      superuser = "@admin";
      # Editing
      htmlok = true;
      locktime = 60 * 60;
      # Media
      im_convert = "${pkgs.imagemagick}/bin/convert";
      # Notification
      subscribe_time = 1;
      registernotify = "robots@${config.rnl.domain}";
      mailfrom = "rnl-wiki@weaver.${config.rnl.domain}";
      htmlmail = false;
      # Advanced
      updatecheck = false;
      # Templates
      tpl = {
        bootstrap3 = {
          bootstrapTheme = "bootswatch";
          showThemeSwitcher = true;
          bootswatchTheme = "spacelab";
          tocAffix = false;
          useGoogleAnalytics = false;
        };
      };
      # Plugins
    };
    templates = with pkgs.dokuwikiTemplates; [bootstrap3];
    plugins = with pkgs.dokuwikiPlugins; [blockquote columns edittable wrap];
    acl = [
      {
        page = "*";
        actor = "@ALL";
        level = 0;
      }
      {
        page = "*";
        actor = "@user";
        level = 16;
      }
      {
        page = "*";
        actor = "@ex";
        level = 1;
      }
    ];
  };
}
