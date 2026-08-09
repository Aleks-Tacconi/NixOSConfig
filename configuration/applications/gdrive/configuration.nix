# Maintains a full offline Google Drive copy with rclone bisync.
{ pkgs, ... }:

let
  gdriveSync = pkgs.writeShellApplication {
    name = "gdrive-sync";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      gnugrep
      libnotify
      rclone
      util-linux
    ];
    text = ''
      set -euo pipefail
      umask 077

      remote_name="gdrive"
      remote="gdrive:"
      local_dir="$HOME/Google Drive"
      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/gdrive-sync"
      work_dir="$state_dir/work"
      filters_file="$state_dir/filters"
      check_filename=".gdrive-bisync-access"
      remote_history="gdrive:.gdrive-sync/history"
      mode=""
      scheduled=false

      usage() {
        cat <<EOF
      Usage: gdrive-sync [status|resync]

        no command  Initialize if needed, otherwise synchronize
        status      Show initialization, scheduling, and failure state
        resync      Rebuild bisync state with Google Drive authoritative
      EOF
      }

      log() {
        printf '%s gdrive-sync: %s\n' "$(date --iso-8601=seconds)" "$*"
      }

      fail() {
        printf 'gdrive-sync: %s\n' "$*" >&2
        exit 2
      }

      notify_failure() {
        notify-send --urgency=critical "Google Drive sync failed" "$1" \
          >/dev/null 2>&1 || true
      }

      record_failure() {
        local run_id="$1"
        local status="$2"
        local report="$3"

        printf 'run=%s\nexit_code=%s\nreport=%s\n' \
          "$run_id" "$status" "$report" >"$state_dir/failure"
      }

      health_check() {
        local failed=0
        local redacted_config=""

        if [[ -e "$local_dir" && ! -d "$local_dir" ]]; then
          log "$local_dir exists but is not a directory" >&2
          failed=1
        elif [[ -d "$local_dir" && ! -w "$local_dir" ]]; then
          log "$local_dir is not writable" >&2
          failed=1
        elif [[ ! -e "$local_dir" && ! -w "$HOME" ]]; then
          log "$HOME is not writable, so $local_dir cannot be created" >&2
          failed=1
        fi

        case "''${RCLONE_NO_CHECK_CERTIFICATE:-false}" in
          1 | true | TRUE | yes | YES)
            log "TLS certificate verification must not be disabled" >&2
            failed=1
            ;;
        esac

        if ! rclone listremotes --ask-password=false \
          | grep --fixed-strings --line-regexp --quiet "$remote"; then
          log "rclone remote $remote is not configured; run 'rclone config'" >&2
          failed=1
        else
          redacted_config="$(rclone config redacted "$remote_name" --ask-password=false 2>/dev/null || true)"
          if ! grep --extended-regexp --quiet \
            '^[[:space:]]*type[[:space:]]*=[[:space:]]*"?drive"?[[:space:]]*$' \
            <<<"$redacted_config"; then
            log "$remote must use rclone's Google Drive backend" >&2
            failed=1
          fi
        fi

        if (( failed == 0 )); then
          if ! rclone lsf --max-depth 1 "$remote" --ask-password=false >/dev/null; then
            log "rclone remote $remote is not accessible" >&2
            failed=1
          elif ! rclone about "$remote" --ask-password=false >/dev/null; then
            log "Google Drive quota information is unavailable" >&2
            failed=1
          fi
        fi

        if (( failed != 0 )); then
          return 1
        fi

        log "health check passed; Google Drive uses verified HTTPS and trash"
      }

      run_logged() {
        local label="$1"
        local report="$2"
        shift 2
        local started=$SECONDS
        local status

        log "$label started"
        set +e
        "$@" 2>&1 | tee "$report"
        status="''${PIPESTATUS[0]}"
        set -e

        if (( status == 0 )); then
          log "$label completed in $((SECONDS - started)) seconds"
          return 0
        fi

        log "$label failed with exit code $status" >&2
        notify_failure "$label failed with exit code $status"
        return "$status"
      }

      # shellcheck disable=SC2329
      prune_local_tree() {
        local root="$1"
        local age_minutes="$2"
        local archive

        [[ -d "$root" ]] || return 0

        while IFS= read -r -d $'\0' archive; do
          printf '%s\n' "$archive"
          find "$archive" -depth -delete
        done < <(find "$root" -mindepth 1 -maxdepth 1 -type d -mmin "+$age_minutes" -print0)
      }

      # shellcheck disable=SC2329
      prune_remote_history() {
        local cutoff
        local listing
        local archive
        local timestamp
        local -a delete_args

        cutoff="$(date --utc --date='30 days ago' +%Y%m%dT%H%M%S)"
        if ! listing="$(rclone lsf "$remote_history" \
          --dirs-only --max-depth 1 --ask-password=false 2>/dev/null)"; then
          log "Drive history is empty; skipping remote pruning"
          return
        fi

        while IFS= read -r archive; do
          archive="''${archive%/}"
          timestamp="''${archive%%-*}"
          if [[ ! "$archive" =~ ^[0-9]{8}T[0-9]{6}-[0-9a-f-]{36}$ || ! "$timestamp" < "$cutoff" ]]; then
            continue
          fi

          printf '%s/%s\n' "$remote_history" "$archive"
          delete_args=(
            "$remote_history/$archive"
            --rmdirs
            --drive-use-trash=false
            --ask-password=false
            --log-level INFO
          )
          rclone delete "''${delete_args[@]}"
          rclone rmdir "$remote_history/$archive" \
            --drive-use-trash=false --ask-password=false
        done <<<"$listing"
      }

      while (( $# > 0 )); do
        case "$1" in
          status | resync)
            [[ -z "$mode" ]] || fail "only one command may be specified"
            mode="$1"
            ;;
          --scheduled)
            scheduled=true
            ;;
          --prune)
            [[ -z "$mode" ]] || fail "only one command may be specified"
            mode="prune"
            ;;
          -h | --help)
            usage
            exit 0
            ;;
          *)
            fail "unknown argument: $1"
            ;;
        esac
        shift
      done

      mode="''${mode:-run}"

      if [[ "$mode" == status ]]; then
        printf 'initializing=%s\ninitialized=%s\nactive=%s\nfailure=%s\n' \
          "$([[ -f "$state_dir/initializing" ]] && printf yes || printf no)" \
          "$([[ -f "$state_dir/initialized" ]] && printf yes || printf no)" \
          "$([[ -f "$state_dir/enabled" ]] && printf yes || printf no)" \
          "$([[ -f "$state_dir/failure" ]] && printf yes || printf no)"
        exit
      fi

      if [[ "$scheduled" == true ]]; then
        if [[ ! -f "$state_dir/enabled" ]]; then
          log "scheduled synchronization is waiting for the first manual 'gdrive-sync'"
          exit
        fi
        if [[ ! -f "$state_dir/initialized" ]]; then
          log "scheduled synchronization is waiting for initialization"
          exit
        fi
        if ! rclone listremotes --ask-password=false \
          | grep --fixed-strings --line-regexp --quiet "$remote"; then
          log "scheduled synchronization is waiting for 'rclone config'"
          exit
        fi
      elif [[ "$mode" == run && ! -f "$state_dir/initialized" ]]; then
        mode="init"
      fi

      health_check
      mkdir -p "$local_dir" "$state_dir/backups" "$state_dir/reports" "$work_dir"
      printf '%s\n' \
        '- /.gdrive-sync/**' \
        '- /PRIVATE*' \
        '- /PRIVATE*/**' \
        '- **/PRIVATE*' \
        '- **/PRIVATE*/**' >"$filters_file"
      exec 9>"$state_dir/run.lock"
      if ! flock --nonblock 9; then
        log "another local sync is already running; skipping"
        exit
      fi

      run_id="$(date --utc +%Y%m%dT%H%M%S)-$(cat /proc/sys/kernel/random/uuid)"
      report_dir="$state_dir/reports/$run_id"
      local_backup="$state_dir/backups/$run_id"
      remote_backup="$remote_history/$run_id"
      mkdir -p "$report_dir"

      bisync_args=(
        "$local_dir"
        "$remote"
        --workdir "$work_dir"
        --filters-file "$filters_file"
        --compare "size,modtime,checksum"
        --conflict-resolve newer
        --conflict-loser num
        --conflict-suffix conflict
        --create-empty-src-dirs
        --check-sync true
        --max-delete 1000
        --max-lock 15m
        --backup-dir1 "$local_backup"
        --backup-dir2 "$remote_backup"
        --drive-export-formats url
        --drive-use-trash=true
        --drive-stop-on-upload-limit
        --ask-password=false
        --retries 3
        --retries-sleep 30s
        --log-level INFO
        --stats 30s
        --stats-one-line
      )

      if [[ "$mode" == init ]]; then
        [[ ! -f "$state_dir/initialized" ]] || fail "this host is already initialized"
        if [[ ! -f "$state_dir/initializing" && -n "$(find "$local_dir" -mindepth 1 -print -quit)" ]]; then
          fail "$local_dir must be completely empty before initialization"
        fi

        : >"$state_dir/initializing"
        if run_logged "access sentinel creation" "$report_dir/access.log" \
          rclone touch "$remote$check_filename" \
            --drive-use-trash=true --ask-password=false; then
          :
        else
          status=$?
          record_failure "$run_id" "$status" "$report_dir/access.log"
          exit "$status"
        fi

        if run_logged "Drive-authoritative initialization" "$report_dir/init.log" \
          rclone bisync "''${bisync_args[@]}" --resync --resync-mode path2; then
          : >"$state_dir/initialized"
          : >"$state_dir/enabled"
          rm -f "$state_dir/failure" "$state_dir/initializing"
          log "initialized; scheduled synchronization is now active"
          exit
        else
          status=$?
          record_failure "$run_id" "$status" "$report_dir/init.log"
          exit "$status"
        fi
      fi

      [[ -f "$state_dir/initialized" ]] || fail "run 'gdrive-sync' first"

      if [[ "$mode" == prune ]]; then
        if run_logged "local history pruning" "$report_dir/local-prune.log" \
          prune_local_tree "$state_dir/backups" 43200; then
          :
        else
          status=$?
          record_failure "$run_id" "$status" "$report_dir/local-prune.log"
          exit "$status"
        fi

        if run_logged "Drive history pruning" "$report_dir/remote-prune.log" \
          prune_remote_history; then
          :
        else
          status=$?
          record_failure "$run_id" "$status" "$report_dir/remote-prune.log"
          exit "$status"
        fi

        if run_logged "report pruning" "$report_dir/report-prune.log" \
          prune_local_tree "$state_dir/reports" 20160; then
          :
        else
          status=$?
          record_failure "$run_id" "$status" "$report_dir/report-prune.log"
          exit "$status"
        fi
        log "retention pruning completed"
        exit
      fi

      if [[ "$mode" == resync ]]; then
        if run_logged "access sentinel creation" "$report_dir/access.log" \
          rclone touch "$remote$check_filename" \
            --drive-use-trash=true --ask-password=false; then
          :
        else
          status=$?
          record_failure "$run_id" "$status" "$report_dir/access.log"
          exit "$status"
        fi

        if run_logged "Drive-authoritative resync" "$report_dir/resync.log" \
          rclone bisync "''${bisync_args[@]}" --resync --resync-mode path2; then
          : >"$state_dir/enabled"
          rm -f "$state_dir/failure"
          exit
        else
          status=$?
          record_failure "$run_id" "$status" "$report_dir/resync.log"
          exit "$status"
        fi
      fi

      if run_logged "bisync" "$report_dir/bisync.log" \
        rclone bisync "''${bisync_args[@]}" \
          --check-access --check-filename "$check_filename" --resilient --recover; then
        rm -f "$state_dir/failure"
        : >"$state_dir/enabled"
        log "sync completed"
        exit
      else
        status=$?
        record_failure "$run_id" "$status" "$report_dir/bisync.log"
        exit "$status"
      fi
    '';
  };

  serviceSettings = {
    Type = "oneshot";
    UMask = "0077";
    Nice = 10;
    NoNewPrivileges = true;
    PrivateTmp = true;
    TimeoutStopSec = "30m";
  };
in
{
  users.users.aleks.linger = true;

  home-manager.users."aleks" = {
    home.packages = [
      gdriveSync
      pkgs.rclone
    ];

    systemd.user = {
      services = {
        google-drive-sync = {
          Unit.Description = "Offline Google Drive bisync";
          Service = serviceSettings // {
            ExecStart = "${gdriveSync}/bin/gdrive-sync --scheduled";
          };
        };

        google-drive-prune = {
          Unit.Description = "Prune expired Google Drive sync history";
          Service = serviceSettings // {
            ExecStart = "${gdriveSync}/bin/gdrive-sync --prune --scheduled";
          };
        };
      };

      timers = {
        google-drive-sync = {
          Unit.Description = "Synchronize Google Drive every five minutes";
          Timer = {
            OnCalendar = "*:0/5:00";
            AccuracySec = "1s";
            RandomizedDelaySec = 0;
            Unit = "google-drive-sync.service";
          };
          Install.WantedBy = [ "timers.target" ];
        };

        google-drive-prune = {
          Unit.Description = "Prune expired Google Drive sync history daily";
          Timer = {
            OnCalendar = "04:00";
            Persistent = true;
            RandomizedDelaySec = "2h";
            Unit = "google-drive-prune.service";
          };
          Install.WantedBy = [ "timers.target" ];
        };
      };
    };
  };
}
