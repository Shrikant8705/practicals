#!/usr/bin/env bash
# =============================================================================
# uninstall.sh - removes everything installed by phase1.sh (Ubuntu / WSL Ubuntu)
#
# Removes: Hadoop, Sqoop, HDFS data, the ~/.bashrc block, downloaded archives,
#          MySQL (server + ALL its databases), OpenJDK, pdsh, Commons Lang.
# Keeps:   the SSH server, your SSH private key, git/curl/wget.
#
# Usage:   bash uninstall.sh [options]
#   --yes          skip the confirmation question
#   --keep-mysql   keep MySQL installed; only drop sqoopuser and the demo databases
#   --keep-java    keep OpenJDK installed
#   -h, --help     show this help
# =============================================================================
set -euo pipefail

ASSUME_YES=0
KEEP_MYSQL=0
KEEP_JAVA=0
for arg in "$@"; do
  case "$arg" in
    --yes|-y)     ASSUME_YES=1 ;;
    --keep-mysql) KEEP_MYSQL=1 ;;
    --keep-java)  KEEP_JAVA=1 ;;
    -h|--help)    sed -n '2,15p' "$0"; exit 0 ;;
    *) echo "Unknown option: $arg (try --help)" >&2; exit 1 ;;
  esac
done

log()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m    OK: %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m    WARN: %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

if [ "$(id -u)" -eq 0 ]; then
  die "Do not run this script as root or with sudo. Run: bash uninstall.sh"
fi

HADOOP_HOME="/usr/local/hadoop"
SQOOP_HOME="/usr/local/sqoop"
DATA_DIR="$HOME/hadoopdata"
DL="$HOME/Downloads"
DOWNLOADED="hadoop-3.3.6.tar.gz sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz mysql-connector-java-5.1.49.jar"

pkgs_matching() { dpkg -l "$1" 2>/dev/null | awk '/^ii/{print $2}' || true; }

MYSQL_PKGS="$(pkgs_matching 'mysql-*' | tr '\n' ' ')"
JAVA_PKGS="$(pkgs_matching 'openjdk-*' | tr '\n' ' ')"
EXTRA_PKGS=""
for p in pdsh libcommons-lang-java; do
  if dpkg -s "$p" >/dev/null 2>&1; then EXTRA_PKGS="$EXTRA_PKGS $p"; fi
done

# ----------------------------- show the plan ---------------------------------
sudo -v   # needed now so the plan can list your MySQL databases
log "This will remove:"
[ -d "$HADOOP_HOME" ] && echo "  - $HADOOP_HOME"
[ -d "$SQOOP_HOME" ]  && echo "  - $SQOOP_HOME"
[ -d "$DATA_DIR" ]    && echo "  - $DATA_DIR  (all HDFS data)"
[ -d "/tmp/hadoop-$USER" ] && echo "  - /tmp/hadoop-$USER"
echo "  - the '# >>> bigdata-lab >>>' block in ~/.bashrc"
echo "  - the SSH login entry for your own key in ~/.ssh/authorized_keys, and localhost entries in known_hosts"
for f in $DOWNLOADED; do
  [ -f "$DL/$f" ] && echo "  - $DL/$f"
done
if [ "$KEEP_MYSQL" -eq 1 ]; then
  echo "  - MySQL user 'sqoopuser' and databases 'sqoop_demo' (and 'college' if it has no tables)  [MySQL itself is kept]"
elif [ -n "${MYSQL_PKGS// /}" ]; then
  echo "  - MySQL packages: $MYSQL_PKGS"
  echo "  - /var/lib/mysql, /etc/mysql  (EVERY MySQL database on this machine)"
  USER_DBS="$(sudo -n mysql -N -e 'SHOW DATABASES' 2>/dev/null | grep -vE '^(information_schema|mysql|performance_schema|sys)$' | tr '\n' ' ' || true)"
  if [ -n "${USER_DBS// /}" ]; then
    printf '\033[1;33m      Databases that will be permanently deleted: %s\033[0m\n' "$USER_DBS"
  fi
fi
if [ "$KEEP_JAVA" -eq 0 ] && [ -n "${JAVA_PKGS// /}" ]; then
  echo "  - Java packages: $JAVA_PKGS"
fi
[ -n "${EXTRA_PKGS// /}" ] && echo "  - Packages:$EXTRA_PKGS"
echo
echo "Kept: SSH server, your SSH private key (~/.ssh/id_rsa), git, curl, wget."

if [ "$ASSUME_YES" -ne 1 ]; then
  printf '\nType "yes" to continue: '
  read -r ANSWER
  if [ "$ANSWER" != "yes" ]; then die "Aborted. Nothing was changed."; fi
fi

# ----------------------------- 1. stop hadoop --------------------------------
log "Step 1/7: Stopping Hadoop"
if [ -x "$HADOOP_HOME/sbin/stop-yarn.sh" ]; then
  "$HADOOP_HOME/sbin/stop-yarn.sh" >/dev/null 2>&1 || true
  "$HADOOP_HOME/sbin/stop-dfs.sh"  >/dev/null 2>&1 || true
fi
pkill -f 'org.apache.hadoop' >/dev/null 2>&1 || true
sleep 2
ok "Hadoop stopped"

# ----------------------------- 2. mysql --------------------------------------
log "Step 2/7: MySQL"
if [ "$KEEP_MYSQL" -eq 1 ]; then
  sudo service mysql start >/dev/null 2>&1 || true
  sleep 3
  if sudo mysql -e "DROP DATABASE IF EXISTS sqoop_demo; DROP USER IF EXISTS 'sqoopuser'@'localhost'; FLUSH PRIVILEGES;" 2>/dev/null; then
    TABLES="$(sudo mysql -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='college'" 2>/dev/null || echo 1)"
    if [ "$TABLES" = "0" ]; then sudo mysql -e "DROP DATABASE IF EXISTS college;" 2>/dev/null || true; fi
    ok "Dropped sqoopuser and sqoop_demo; MySQL kept"
  else
    warn "Could not reach MySQL, skipped dropping the Sqoop user and demo database"
  fi
elif [ -n "${MYSQL_PKGS// /}" ]; then
  sudo service mysql stop >/dev/null 2>&1 || true
  # shellcheck disable=SC2086
  sudo apt-get purge -y $MYSQL_PKGS
  sudo rm -rf /var/lib/mysql /etc/mysql /var/log/mysql /var/run/mysqld
  ok "MySQL removed"
else
  ok "MySQL not installed"
fi

# ----------------------------- 3. folders ------------------------------------
log "Step 3/7: Removing Hadoop, Sqoop and data folders"
sudo rm -rf "$HADOOP_HOME" "$SQOOP_HOME"
rm -rf "$DATA_DIR" "/tmp/hadoop-$USER"
for f in $DOWNLOADED; do rm -f "$DL/$f"; done
ok "Folders and downloaded archives removed"

# ----------------------------- 4. bashrc -------------------------------------
log "Step 4/7: Cleaning ~/.bashrc"
if [ -f "$HOME/.bashrc" ]; then
  sed -i '/# >>> bigdata-lab >>>/,/# <<< bigdata-lab <<</d' "$HOME/.bashrc"
  LEFT="$(grep -nE 'HADOOP_HOME|SQOOP_HOME|JAVA_HOME' "$HOME/.bashrc" || true)"
  if [ -n "$LEFT" ]; then
    warn "These lines were NOT created by phase1.sh (maybe from the manual steps). Remove them yourself if unwanted:"
    echo "$LEFT" | sed 's/^/      /'
  fi
fi
ok "~/.bashrc cleaned"

# ----------------------------- 5. ssh ----------------------------------------
log "Step 5/7: SSH entries"
if [ -f "$HOME/.ssh/id_rsa.pub" ] && [ -f "$HOME/.ssh/authorized_keys" ]; then
  TMP="$(mktemp)"
  grep -vxF "$(cat "$HOME/.ssh/id_rsa.pub")" "$HOME/.ssh/authorized_keys" > "$TMP" || true
  cat "$TMP" > "$HOME/.ssh/authorized_keys"
  rm -f "$TMP"
fi
for h in localhost 127.0.0.1 0.0.0.0; do
  ssh-keygen -R "$h" >/dev/null 2>&1 || true
done
rm -f "$HOME/.ssh/known_hosts.old"
ok "SSH localhost entries removed (private key and SSH server left alone)"

# ----------------------------- 6. packages -----------------------------------
log "Step 6/7: Removing packages"
REMOVE=""
if [ "$KEEP_JAVA" -eq 0 ]; then REMOVE="$JAVA_PKGS"; fi
REMOVE="$REMOVE $EXTRA_PKGS"
if [ -n "${REMOVE// /}" ]; then
  # shellcheck disable=SC2086
  sudo apt-get purge -y $REMOVE
  ok "Packages removed"
else
  ok "No extra packages to remove"
fi

# ----------------------------- 7. cleanup ------------------------------------
log "Step 7/7: Cleaning up unused dependencies"
sudo apt-get autoremove -y --purge
sudo apt-get clean

cat <<'MSG'

=============================================================================
 Everything installed by phase1.sh has been removed.

 Your CURRENT terminal still remembers the old variables. Either open a new
 terminal, or run:

   unset JAVA_HOME HADOOP_HOME HADOOP_MAPRED_HOME HADOOP_CONF_DIR SQOOP_HOME PDSH_RCMD_TYPE
   hash -r

 To check nothing is left:   jps ; sqoop version ; mysql --version
 (each should say "command not found")
=============================================================================
MSG