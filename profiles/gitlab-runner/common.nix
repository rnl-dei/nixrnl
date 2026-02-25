{ ... }:
{
  services.gitlab-runner = {
    enable = true;
    concurrent = 1000; # arbitrarily large number so concurrency is handled by individual limit option in each runner
    settings = {
      log_level = "info";
    };
  };
}
