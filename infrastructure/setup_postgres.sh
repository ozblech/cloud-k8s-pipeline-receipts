#!/bin/bash
exec > >(tee /var/log/postgres-bootstrap.log | logger -t user-data -s) 2>&1
# set -eux means the script will exit on any error and print each command before executing it
set -eux

# Update and install dependencies
dnf update -y --allowerasing || echo "dnf update failed"
# Install PostgreSQL 16
dnf install -y postgresql16 postgresql16-server

# 3. Initialize the PostgreSQL data directory
postgresql-setup --initdb

# 4. Start and enable PostgreSQL service
systemctl enable --now postgresql

# 5. Configure PostgreSQL to auto-restart if it crashes
mkdir -p /etc/systemd/system/postgresql.service.d
echo "[Service]
Restart=on-failure
RestartSec=5s" | tee /etc/systemd/system/postgresql.service.d/override.conf

# Reload systemd and restart PostgreSQL
systemctl daemon-reexec
systemctl daemon-reload
systemctl restart postgresql

# 6. Harden authentication: switch to postgres user and set up DB and user
sudo -u postgres psql <<EOF
CREATE USER receipts_user WITH PASSWORD 'VeryStrongPassword123!';
CREATE DATABASE receipts;
GRANT ALL PRIVILEGES ON DATABASE receipts TO receipts_user;
EOF

# 7. Harden authentication method in pg_hba.conf
PG_HBA=$(sudo -u postgres psql -t -P format=unaligned -c "SHOW hba_file;")
sudo sed -i 's/^\(local\s\+all\s\+all\s\+\)ident/\1md5/' "$PG_HBA"
sudo sed -i 's/^\(host\s\+all\s\+all\s\+127\.0\.0\.1\/32\s\+\)ident/\1md5/' "$PG_HBA"

# 8. Restart PostgreSQL to apply changes
systemctl restart postgresql

# 9. Show final service status
systemctl status postgresql

# /var/lib/pgsql/ is owned by LINUX postgres user
# postgresql was installed in /usr/bin/psql 
# ps aux | grep '[p]ostgres' 
# shows that postgres is running as user postgres