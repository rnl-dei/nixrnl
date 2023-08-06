{
  config,
  lib,
  ...
}:
with lib; {
  options.rnl.labels = {
    core = mkOption {
      type = types.nullOr types.str;
      description = "Core label of host";
      default = "";
      example = "rnl";
    };
    type = mkOption {
      type = types.nullOr types.str;
      description = "Type of host";
      default = "";
      example = "vm";
    };
    location = mkOption {
      type = types.nullOr types.str;
      description = "Location of host";
      default = "";
      example = "inf1-p2-lab1";
    };
    os = mkOption {
      type = types.nullOr types.str;
      description = "Operating system of host";
      default = "";
      example = "debian";
    };
  };

  config = {
    # This assertions helps to detect missing labels
    assertions = [
      {
        assertion = config.rnl.labels.core != "";
        message = "Host '${config.networking.hostName}' must have a core label";
      }
      {
        assertion = config.rnl.labels.type != "";
        message = "Host '${config.networking.hostName}' must have a type label";
      }
      {
        assertion = config.rnl.labels.location != "";
        message = "Host '${config.networking.hostName}' must have a location label";
      }
      {
        assertion = config.rnl.labels.os != "";
        message = "Host '${config.networking.hostName}' must have an OS label";
      }
    ];
  };
}
