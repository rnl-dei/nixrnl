{
  config,
  pkgs,
  lib,
  ...
}:
let
  # External S3 mounts configuration
  # This is used for drives that's shared between 'DMS' API and 'Secretaria' users
  # All share the same key/secret/hostname, so we define them once
  s3Mounts = [
    {
      mountPoint = "[BLATTA] DMS File Repository";
      bucket = "blatta";
      groups = [
        "Secretaria"
        "DEI"
      ];
    }
    {
      mountPoint = "DMS File Repository";
      bucket = "dei";
      groups = [ "Secretaria" ];
    }
  ];

  # Team folders to be created
  # These are folders shared with specific groups, without API access
  # (still managed by S3 under the hood anyway, but passed to Nextcloud only)
  teamFolders = [
    {
      name = "RNL Team";
      groups = [
        {
          name = "RNL";
          permissions = "share write delete";
        }
        {
          name = "DEI";
          permissions = "share write delete";
        }
      ];
    }
    {
      name = "Bolseiros DEI";
      groups = [
        {
          name = "RNL";
          permissions = "share write delete";
        }
        {
          name = "DEI";
          permissions = "share write delete";
        }
      ];
    }
  ];

  nextcloudOcc = "${config.services.nextcloud.occ}/bin/nextcloud-occ";

  # Function to generate the mount script for a given mount
  mkMountScript =
    {
      mountPoint,
      bucket,
      groups,
    }:
    ''

      # Check if mount point already exists
      MOUNT_ID=$(
        ${nextcloudOcc} files_external:list --output=json |
        sed -n '/^\[/,$p' | \
        ${pkgs.jq}/bin/jq -r --arg mp "${mountPoint}" '
          .[] 
          | select((.mount_point | sub("^/";"")) == ($mp | sub("^/";"")))
          | .mount_id
        ' | head -n1
      )

      # If not, create it using the shared S3 credentials variables
      if [ -z "$MOUNT_ID" ]; then
        MOUNT_ID=$(
          ${nextcloudOcc} files_external:create \
            -c bucket="${bucket}" \
            -c hostname="${config.services.garage.settings.s3_api.root_domain}" \
            -c region="garage" \
            -c use_ssl=true \
            -c use_path_style=true \
            -c useMultipartCopy=true \
            -c key="$S3_KEY" \
            -c secret="$S3_SECRET" \
            "${mountPoint}" amazons3 amazons3::accesskey \
            --output=json
        )
      fi

      # Reset and apply groups
      if [ ! -z "$MOUNT_ID" ]; then
        ${nextcloudOcc} files_external:applicable --remove-all "$MOUNT_ID"
        ${lib.concatMapStringsSep "\n" (
          g: "${nextcloudOcc} files_external:applicable --add-group=\"${g}\" \"$MOUNT_ID\""
        ) groups}
      fi
    '';

  mkTeamFolderScript =
    { name, groups }:
    ''

      # Check if group folder already exists
      FOLDER_ID=$(
        ${nextcloudOcc} groupfolders:list --output=json | \
        ${pkgs.jq}/bin/jq -r --arg name "${name}" '
          .[] 
          | select(.mount_point == $name)
          | .id
        ' | head -n1 | tr -dc '0-9'
      )

      # If not, create it
      if [ -z "$FOLDER_ID" ]; then
        FOLDER_ID=$(${nextcloudOcc} groupfolders:create "${name}" | tr -dc '0-9')
      fi

      # Reset and apply groups
      if [ ! -z "$FOLDER_ID" ]; then
        ${lib.concatMapStringsSep "\n" (g: ''
          ${nextcloudOcc} groupfolders:group "$FOLDER_ID" "${g.name}" ${g.permissions}
        '') groups}
      fi
    '';
in
{
  systemd.services.nextcloud-s3-mounts = {
    description = "Nextcloud External Storage S3 Mounts Setup";
    after = [ "nextcloud-runtime-config.service" ];
    requires = [ "nextcloud-runtime-config.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
    };
    script =
      let
        nextcloudOcc = "${config.services.nextcloud.occ}/bin/nextcloud-occ";
        jq = "${pkgs.jq}/bin/jq";
      in
      ''
        # Enable the external storage app
        ${nextcloudOcc} app:enable files_external

        # Configure External Storage S3
        S3_KEY=$(${jq} -r '.objectstore.arguments.key' ${config.age.secrets.dei-nextcloud-secretFile.path})
        S3_SECRET=$(${jq} -r '.objectstore.arguments.secret' ${config.age.secrets.dei-nextcloud-secretFile.path})

        # Inject the generated script for all mounts defined in 's3Mounts'
        ${lib.concatMapStringsSep "\n" mkMountScript s3Mounts}

        # Inject the generated script for all team folders defined in 'teamFolders'
        ${lib.concatMapStringsSep "\n" mkTeamFolderScript teamFolders}
      '';
  };
}
