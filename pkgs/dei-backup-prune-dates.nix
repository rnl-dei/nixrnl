{
  coreutils,
  gnugrep,
  writeShellApplication,
  ...
}:
# Reads backup dates (YYYY-MM-DD, one per line) from stdin and prints the ones to delete.
# Retention policy:
#  - younger than 30 days: keep everything (daily)
#  - 30 to 90 days: keep the oldest backup of each week
#  - 90 to 180 days: keep the oldest backup of each 3-week period
#  - 180 days or older: delete everything
# Buckets are aligned to the epoch, and the oldest backup in a bucket is the one kept,
# so a kept backup stays kept as it ages into the next tier.
writeShellApplication {
  name = "dei-backup-prune-dates";
  runtimeInputs = [
    coreutils
    gnugrep
  ];
  text = ''
    today=$(( $(date -u -d "$(date -u +%F)" +%s) / 86400 ))
    declare -A seen=()
    grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' | sort -u | while read -r d; do
      day=$(( $(date -u -d "$d" +%s) / 86400 ))
      age=$(( today - day ))
      if (( age >= 180 )); then
        echo "$d"
        continue
      elif (( age >= 90 )); then
        bucket="3w-$(( day / 21 ))"
      elif (( age >= 30 )); then
        bucket="1w-$(( day / 7 ))"
      else
        continue
      fi
      if [[ -n "''${seen[$bucket]:-}" ]]; then
        echo "$d"
      else
        seen[$bucket]=1
      fi
    done
  '';
}
