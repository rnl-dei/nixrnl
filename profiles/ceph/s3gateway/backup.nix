{ pkgs, ... }:
let
  bash_script = pkgs.writeShellScript "script" ''
    POOL="virtual"
    IMAGES=$(/bin/rbd ls $POOL)

    NOW_HOUR=$(date +%Y%m%d-%H)
    NOW_DAY=$(date +%Y%m%d)
    NOW_MONTH=$(date +%Y%m)

    for IMG in $IMAGES; do

      /bin/rbd snap create ''\${POOL}/''\${IMG}@hourly-''\${NOW_HOUR}

      /bin/rbd snap create ''\${POOL}/''\${IMG}@daily-''\${NOW_DAY} 2>/dev/null

      /bin/rbd snap create ''\${POOL}/''\${IMG}@monthly-''\${NOW_MONTH} 2>/dev/null

      #PRUNING
      # Keep every 6 hours of the day
      /bin/rbd snap ls ''\${POOL}/''\${IMG} | grep "hourly-" | /bin/awk '{print $2}' | sort -r | tail -n +5 | xargs -I {} /bin/rbd snap rm ''\${POOL}/''\${IMG}@{} 2>/dev/null

      # Keep week
      /bin/rbd snap ls ''\${POOL}/''\${IMG} | grep "daily-" | /bin/awk '{print $2}' | sort -r | tail -n +8 | xargs -I {} /bin/rbd snap rm ''\${POOL}/''\${IMG}@{} 2>/dev/null

      # Keep month
      /bin/rbd snap ls ''\${POOL}/''\${IMG} | grep "monthly-" | /bin/awk '{print $2}' | sort -r | tail -n +2 | xargs -I {} /bin/rbd snap rm ''\${POOL}/''\${IMG}@{} 2>/dev/null
    done

  '';
in
{
  systemd.timers.ceph_snapshot = {

    enable = true;
    description = "Manage ceph snapshots";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = "*-*-* 0/6:00:00";
      Persistent = true;
    };

  };

  systemd.services.ceph_snapshot = {

    enable = true;
    description = "Manage ceph snapshots";
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      User = "root";
      Type = "oneshot";
      TimeoutStartSec = 600;
      ExecStart = bash_script;
    };

  };
}
