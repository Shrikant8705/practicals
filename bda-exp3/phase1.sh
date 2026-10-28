#!/usr/bin/env bash
# =============================================================================
# phase1.sh - Big Data Lab Practical 2, Phase 1 (one-time setup)
# Installs: Java 8/11, SSH, Hadoop 3.3.6, Sqoop 1.4.7, MySQL, Connector/J 5.1.49
# Target:   Ubuntu on WSL 2 (also works on plain Ubuntu)
# Safe to re-run: every step checks whether it is already done.
#
# Run it with:   bash phase1.sh        (do NOT run with sudo)
# =============================================================================
set -euo pipefail

# ----------------------------- settings --------------------------------------
HADOOP_VERSION="3.3.6"
SQOOP_VERSION="1.4.7"
SQOOP_TARBALL="sqoop-${SQOOP_VERSION}.bin__hadoop-2.6.0"
CONNECTOR_VERSION="5.1.49"
SQOOP_DB_USER="sqoopuser"
SQOOP_DB_PASS="Sqoop123"

HADOOP_HOME="/usr/local/hadoop"
SQOOP_HOME="/usr/local/sqoop"
DATA_DIR="$HOME/hadoopdata"          # HDFS data lives here (survives WSL restarts)
DL="$HOME/Downloads"

BASHRC_BEGIN="# >>> bigdata-lab >>>"
BASHRC_END="# <<< bigdata-lab <<<"

# ----------------------------- helpers ---------------------------------------
log()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m    OK: %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m    WARN: %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

if [ "$(id -u)" -eq 0 ]; then
  die "Do not run this script as root or with sudo. Run: bash phase1.sh"
fi

if grep -qi microsoft /proc/version 2>/dev/null; then
  ok "WSL detected"
  case "$PWD" in
    /mnt/*) warn "You are inside /mnt/c (Windows drive). It works, but the Linux home (~) is faster." ;;
  esac
fi

# Ask for the sudo password once and keep it alive while the script runs
sudo -v
( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) &
KEEPALIVE_PID=$!
trap 'kill "$KEEPALIVE_PID" 2>/dev/null || true' EXIT

export DEBIAN_FRONTEND=noninteractive
mkdir -p "$DL"

# ----------------------------- 1. packages -----------------------------------
log "Step 1/10: Installing base packages (ssh, pdsh, wget, Commons Lang)"
sudo apt-get update -y
sudo apt-get install -y ssh pdsh wget curl ca-certificates libcommons-lang-java
ok "Base packages installed"

# ----------------------------- 2. java ---------------------------------------
log "Step 2/10: Java (8 preferred, 11 as fallback)"
find_java() {
  local j=""
  j=$(find /usr/lib/jvm -maxdepth 1 -type d -name 'java-8-openjdk-*' 2>/dev/null | head -n1 || true)
  if [ -z "$j" ]; then
    j=$(find /usr/lib/jvm -maxdepth 1 -type d -name 'java-11-openjdk-*' 2>/dev/null | head -n1 || true)
  fi
  echo "$j"
}
JAVA_HOME="$(find_java)"
if [ -z "$JAVA_HOME" ]; then
  sudo apt-get install -y openjdk-8-jdk || sudo apt-get install -y openjdk-11-jdk \
    || die "Could not install OpenJDK 8 or 11. Tell me your Ubuntu version (lsb_release -a)."
  JAVA_HOME="$(find_java)"
fi
[ -n "$JAVA_HOME" ] || die "Java installed but JAVA_HOME could not be detected."
export JAVA_HOME
ok "JAVA_HOME=$JAVA_HOME"

# ----------------------------- 3. ssh ----------------------------------------
log "Step 3/10: Passwordless SSH to localhost"
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
if [ ! -f "$HOME/.ssh/id_rsa" ]; then
  ssh-keygen -t rsa -P "" -f "$HOME/.ssh/id_rsa" -q
fi
touch "$HOME/.ssh/authorized_keys"
if ! grep -qF "$(cat "$HOME/.ssh/id_rsa.pub")" "$HOME/.ssh/authorized_keys"; then
  cat "$HOME/.ssh/id_rsa.pub" >> "$HOME/.ssh/authorized_keys"
fi
chmod 600 "$HOME/.ssh/authorized_keys"

sudo ssh-keygen -A >/dev/null 2>&1 || true       # make sure the SSH server has host keys
sudo service ssh start || sudo service ssh restart
sleep 2
# Pre-accept host keys so Hadoop scripts never stop at the "yes/no" question
ssh-keyscan -H localhost 127.0.0.1 0.0.0.0 >> "$HOME/.ssh/known_hosts" 2>/dev/null || true
if ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new localhost true; then
  ok "ssh localhost works without a password"
else
  die "Passwordless SSH failed. Run 'ssh localhost' manually and check the error."
fi

# ----------------------------- 4. hadoop -------------------------------------
log "Step 4/10: Installing Hadoop ${HADOOP_VERSION}"
if [ -x "$HADOOP_HOME/bin/hadoop" ]; then
  ok "Hadoop already installed at $HADOOP_HOME (skipping)"
else
  HADOOP_TGZ="hadoop-${HADOOP_VERSION}.tar.gz"
  wget -c -P "$DL" "https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_TGZ}"
  tar -xzf "$DL/$HADOOP_TGZ" -C "$DL"
  sudo rm -rf "$HADOOP_HOME"
  sudo mv "$DL/hadoop-${HADOOP_VERSION}" "$HADOOP_HOME"
  ok "Hadoop moved to $HADOOP_HOME"
fi
sudo chown -R "$USER":"$USER" "$HADOOP_HOME"

# ----------------------------- 5. environment --------------------------------
log "Step 5/10: Environment variables in ~/.bashrc"
sed -i "\|$BASHRC_BEGIN|,\|$BASHRC_END|d" "$HOME/.bashrc"
cat >> "$HOME/.bashrc" <<EOF
$BASHRC_BEGIN
export JAVA_HOME=$JAVA_HOME
export HADOOP_HOME=$HADOOP_HOME
export HADOOP_MAPRED_HOME=\$HADOOP_HOME
export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop
export SQOOP_HOME=$SQOOP_HOME
export PDSH_RCMD_TYPE=ssh
export PATH=\$PATH:\$JAVA_HOME/bin:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin:\$SQOOP_HOME/bin
$BASHRC_END
EOF

# Same variables for the rest of this script
export HADOOP_HOME SQOOP_HOME
export HADOOP_MAPRED_HOME="$HADOOP_HOME"
export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
export PDSH_RCMD_TYPE=ssh
export PATH="$PATH:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SQOOP_HOME/bin"
ok "Variables written to ~/.bashrc"

# ----------------------------- 6. hadoop config ------------------------------
log "Step 6/10: Configuring Hadoop (5 files)"
CONF="$HADOOP_HOME/etc/hadoop"
for f in hadoop-env.sh core-site.xml hdfs-site.xml mapred-site.xml yarn-site.xml; do
  cp -n "$CONF/$f" "$CONF/$f.orig" 2>/dev/null || true     # keep one backup of the original
done

sed -i '/^export JAVA_HOME=/d' "$CONF/hadoop-env.sh"
echo "export JAVA_HOME=$JAVA_HOME" >> "$CONF/hadoop-env.sh"

cat > "$CONF/core-site.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://localhost:9000</value>
  </property>
  <property>
    <name>hadoop.tmp.dir</name>
    <value>$DATA_DIR</value>
  </property>
</configuration>
EOF

cat > "$CONF/hdfs-site.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <property>
    <name>dfs.replication</name>
    <value>1</value>
  </property>
</configuration>
EOF

cat > "$CONF/mapred-site.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
  <property>
    <name>mapreduce.application.classpath</name>
    <value>$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/*:$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/lib/*</value>
  </property>
  <property>
    <name>yarn.app.mapreduce.am.env</name>
    <value>HADOOP_MAPRED_HOME=${HADOOP_HOME}</value>
  </property>
  <property>
    <name>mapreduce.map.env</name>
    <value>HADOOP_MAPRED_HOME=${HADOOP_HOME}</value>
  </property>
  <property>
    <name>mapreduce.reduce.env</name>
    <value>HADOOP_MAPRED_HOME=${HADOOP_HOME}</value>
  </property>
</configuration>
EOF

cat > "$CONF/yarn-site.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>
  <property>
    <name>yarn.nodemanager.env-whitelist</name>
    <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,HADOOP_YARN_HOME,HADOOP_MAPRED_HOME</value>
  </property>
  <property>
    <name>yarn.nodemanager.vmem-check-enabled</name>
    <value>false</value>
  </property>
</configuration>
EOF
ok "Hadoop configuration written"

# ----------------------------- 7. format + start -----------------------------
log "Step 7/10: Formatting NameNode (first time only) and starting Hadoop"
if [ -d "$DATA_DIR/dfs/name/current" ]; then
  ok "NameNode already formatted (skipping format)"
else
  hdfs namenode -format -force -nonInteractive
  ok "NameNode formatted"
fi

if jps | grep -q NameNode; then
  ok "Hadoop daemons already running"
else
  start-dfs.sh
  start-yarn.sh
fi
sleep 5
hdfs dfsadmin -safemode wait >/dev/null 2>&1 || true
hdfs dfs -mkdir -p /sqoop
hdfs dfs -ls / >/dev/null && ok "HDFS is working"
echo "    Running daemons:"
jps | sed 's/^/      /'

# ----------------------------- 8. sqoop --------------------------------------
log "Step 8/10: Installing Sqoop ${SQOOP_VERSION}"
if [ -x "$SQOOP_HOME/bin/sqoop" ]; then
  ok "Sqoop already installed at $SQOOP_HOME (skipping download)"
else
  wget -c -P "$DL" "https://archive.apache.org/dist/sqoop/${SQOOP_VERSION}/${SQOOP_TARBALL}.tar.gz"
  tar -xzf "$DL/${SQOOP_TARBALL}.tar.gz" -C "$DL"
  sudo rm -rf "$SQOOP_HOME"
  sudo mv "$DL/$SQOOP_TARBALL" "$SQOOP_HOME"
  ok "Sqoop moved to $SQOOP_HOME"
fi
sudo chown -R "$USER":"$USER" "$SQOOP_HOME"

# sqoop-env.sh with Hadoop paths
cd "$SQOOP_HOME/conf"
[ -f sqoop-env.sh ] || cp sqoop-env-template.sh sqoop-env.sh
sed -i '/^export HADOOP_COMMON_HOME=/d;/^export HADOOP_MAPRED_HOME=/d;/^export HADOOP_CONF_DIR=/d' sqoop-env.sh
cat >> sqoop-env.sh <<EOF
export HADOOP_COMMON_HOME=$HADOOP_HOME
export HADOOP_MAPRED_HOME=$HADOOP_HOME
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
EOF
cd "$HOME"
ok "sqoop-env.sh configured"

# Commons Lang (fixes NoClassDefFoundError: StringUtils)
if [ -f /usr/share/java/commons-lang.jar ]; then
  cp /usr/share/java/commons-lang.jar "$SQOOP_HOME/lib/"
else
  warn "commons-lang.jar not in /usr/share/java, downloading from Maven"
  wget -c -P "$SQOOP_HOME/lib" "https://repo.maven.apache.org/maven2/commons-lang/commons-lang/2.6/commons-lang-2.6.jar"
fi
ok "Commons Lang copied to Sqoop lib"

# MySQL JDBC driver (fixes: Could not load db driver class)
CONNECTOR_JAR="mysql-connector-java-${CONNECTOR_VERSION}.jar"
wget -c -P "$DL" "https://repo.maven.apache.org/maven2/mysql/mysql-connector-java/${CONNECTOR_VERSION}/${CONNECTOR_JAR}"
cp "$DL/$CONNECTOR_JAR" "$SQOOP_HOME/lib/"
ok "MySQL Connector/J copied to Sqoop lib"

# ----------------------------- 9. mysql --------------------------------------
log "Step 9/10: Installing MySQL and creating '$SQOOP_DB_USER'"
sudo apt-get install -y mysql-server

# WSL has no auto-start for services; start it (works on normal Ubuntu too)
sudo service mysql start || sudo service mysql restart
for i in $(seq 1 30); do
  if sudo mysqladmin ping --silent >/dev/null 2>&1; then break; fi
  sleep 2
done
sudo mysqladmin ping --silent >/dev/null 2>&1 || die "MySQL did not start. Try: sudo service mysql start"
ok "MySQL is running"

create_sqoop_user() {
  sudo mysql <<SQL
CREATE USER IF NOT EXISTS '${SQOOP_DB_USER}'@'localhost' IDENTIFIED WITH mysql_native_password BY '${SQOOP_DB_PASS}';
ALTER USER '${SQOOP_DB_USER}'@'localhost' IDENTIFIED WITH mysql_native_password BY '${SQOOP_DB_PASS}';
GRANT ALL PRIVILEGES ON *.* TO '${SQOOP_DB_USER}'@'localhost';
CREATE DATABASE IF NOT EXISTS college;
FLUSH PRIVILEGES;
SQL
}

if ! create_sqoop_user 2>/dev/null; then
  warn "mysql_native_password seems disabled (MySQL 8.4+). Enabling it and retrying."
  printf '[mysqld]\nmysql_native_password=ON\n' | sudo tee /etc/mysql/conf.d/zz-native-password.cnf >/dev/null
  sudo service mysql restart
  sleep 5
  create_sqoop_user || die "Could not create $SQOOP_DB_USER. Send me the exact error message."
fi
ok "User $SQOOP_DB_USER created (password: $SQOOP_DB_PASS) and 'college' database ensured"
sudo mysql -e "SELECT user, host, plugin FROM mysql.user WHERE user='${SQOOP_DB_USER}';"

# ----------------------------- 10. verify ------------------------------------
log "Step 10/10: Final verification"
echo "--- sqoop version ---"
sqoop version 2>&1 | grep -E "Sqoop [0-9]" || warn "sqoop version printed no version line"

echo "--- sqoop list-databases ---"
DB_OUT="$(sqoop list-databases \
  --connect "jdbc:mysql://localhost:3306/?useSSL=false" \
  --username "$SQOOP_DB_USER" --password "$SQOOP_DB_PASS" 2>/dev/null || true)"
echo "$DB_OUT"

if echo "$DB_OUT" | grep -q "college"; then
  ok "Sqoop can talk to MySQL"
else
  warn "list-databases did not show 'college'. Run it manually (without 2>/dev/null) to see the error."
fi

cat <<'MSG'

=============================================================================
 Phase 1 finished.

 1. Load the new variables into THIS terminal:   source ~/.bashrc

 2. WSL stops all services when you close the terminal / shut WSL down.
    At the start of every new session run:

      sudo service ssh start
      sudo service mysql start
      start-dfs.sh
      start-yarn.sh
      jps

    You should see: NameNode DataNode SecondaryNameNode ResourceManager NodeManager

 3. Then run Phase 2 (the actual practical).
=============================================================================
MSG