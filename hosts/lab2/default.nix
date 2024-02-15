{
  config,
  profiles,
  ...
}: {
  imports = with profiles; [
    core.rnl
    filesystems.labs
    os.nixos
    type.physical

    labs
    gitlab-runner
  ];

  networking.enableIPv6 = false;

  rnl.storage.disks.root = ["/dev/nvme0n1"];
  rnl.windows-labs.partition = "/dev/nvme0n1p2";

  rnl.labels.location = "inf1-p2-lab2";

  services.gitlab-runner.services.default = {
    registrationConfigFile = config.age.secrets."gitlab-runner-lab2.env".path;
    description = "gitlab-runner-lab2";
  };

  age.secrets."gitlab-runner-lab2.env" = {
    file = ../../secrets/gitlab-runner-lab2-env.age;
    owner = "root";
    mode = "0400";
  };
}
