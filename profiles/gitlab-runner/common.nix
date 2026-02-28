{ ... }:
{
  services.gitlab-runner = {
    enable = true;
    settings = {
      concurrent = 1000;
      log_level = "info";
    };
  };
}
