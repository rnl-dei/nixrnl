{config, profiles, ...}: {
  imports = with profiles; [
    core.rnl
    filesystems.labs
    os.nixos
    type.physical

    labs
    gitlab-runner
  ];

  rnl.storage.disks.root = ["/dev/nvme0n1"];
  rnl.windows-labs.partition = "/dev/nvme0n1p2";

  rnl.labels.location = "inf1-p2-lab5";

  services.gitlab-runner.services.default = {
    registrationConfigFile = config.age.secrets."gl-runner-lab5.env".path;
    description = "gitlab-runner-lab5";
  };

  age.secrets."gl-runner-lab5.env" = {
    file = ../../secrets/gitlab-runners/lab5-env.age;
    owner = "root";
    mode = "0400";
  };
}
