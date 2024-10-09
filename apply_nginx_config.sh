#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
    export $(cat .env | xargs)
else
    echo ".env file not found! Exiting..."
    exit 1
fi

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

# Install necessary dependencies: NGINX, Prometheus, Grafana, LuaJIT, and lua-resty-postgres
echo "Installing necessary dependencies..."

# Update and install system packages
apt-get update

# Install NGINX if not already installed
if ! dpkg -s nginx &> /dev/null; then
    echo "Installing NGINX..."
    apt-get install -y nginx
else
    echo "NGINX is already installed, skipping installation."
fi

# Install Lua5.1 and related packages if not already installed
if ! dpkg -s lua5.1 liblua5.1-dev libnginx-mod-http-lua &> /dev/null; then
    echo "Installing Lua5.1 and necessary packages..."
    apt-get install -y lua5.1 liblua5.1-dev libnginx-mod-http-lua
else
    echo "Lua5.1 and necessary packages are already installed, skipping installation."
fi

# Install LuaRocks and lua-resty-postgres if not installed
if ! command -v luarocks &> /dev/null || ! luarocks list | grep -q lua-resty-postgres; then
    echo "Installing LuaRocks and lua-resty-postgres..."
    apt-get install -y luarocks
    luarocks install lua-resty-postgres
else
    echo "LuaRocks and lua-resty-postgres are already installed, skipping installation."
fi

# Install Certbot and related packages if not installed
if ! dpkg -s certbot python3-certbot-nginx &> /dev/null; then
    echo "Installing Certbot and related packages..."
    apt-get install -y certbot python3-certbot-nginx
else
    echo "Certbot is already installed, skipping installation."
fi

# Install Prometheus if not already installed
if ! command -v prometheus &> /dev/null; then
    echo "Installing Prometheus..."
    wget https://github.com/prometheus/prometheus/releases/download/v2.46.0/prometheus-2.46.0.linux-amd64.tar.gz
    tar -xvf prometheus-*.tar.gz
    cp prometheus-*/prometheus /usr/local/bin/
    cp prometheus-*/promtool /usr/local/bin/
    mkdir -p /etc/prometheus /var/lib/prometheus
    cp prometheus-*/prometheus.yml /etc/prometheus/
    cp -r prometheus-*/consoles /etc/prometheus/
    cp -r prometheus-*/console_libraries /etc/prometheus/

    # Create Prometheus systemd service
    cat <<EOL > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=root
ExecStart=/usr/local/bin/prometheus \\
  --config.file=/etc/prometheus/prometheus.yml \\
  --storage.tsdb.path=/var/lib/prometheus/ \\
  --web.console.templates=/etc/prometheus/consoles \\
  --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOL

    # Reload systemd, enable and start Prometheus service
    systemctl daemon-reload
    systemctl enable prometheus
    systemctl start prometheus
else
    echo "Prometheus is already installed, skipping installation."
fi

# Install Grafana if not already installed
if ! dpkg -s grafana &> /dev/null; then
    echo "Installing Grafana..."
    wget https://dl.grafana.com/oss/release/grafana_8.3.0_amd64.deb
    dpkg -i grafana_8.3.0_amd64.deb
    systemctl enable grafana-server
    systemctl start grafana-server
else
    echo "Grafana is already installed, skipping installation."
fi

# Copy NGINX configuration from the local "api.histori.xyz" file if it doesn't exist
if [ ! -f /etc/nginx/sites-available/api.histori.xyz ]; then
    if [ -f api.histori.xyz ]; then
        cp api.histori.xyz /etc/nginx/sites-available/api.histori.xyz
    else
        echo "NGINX configuration file api.histori.xyz not found! Exiting..."
        exit 1
    fi
else
    echo "NGINX configuration file already exists, skipping copy."
fi

# Symlink the configuration to sites-enabled
ln -sf /etc/nginx/sites-available/api.histori.xyz /etc/nginx/sites-enabled/

# Test NGINX configuration for errors
nginx -t
if [ $? -ne 0 ]; then
    echo "NGINX configuration test failed! Exiting..."
    exit 1
fi

# Reload NGINX to apply changes
systemctl reload nginx

# Set up Prometheus scraping configuration to monitor NGINX
if ! grep -q "job_name: 'nginx'" /etc/prometheus/prometheus.yml; then
    echo "Setting up Prometheus to scrape NGINX metrics..."
    cat <<EOL >> /etc/prometheus/prometheus.yml
scrape_configs:
  - job_name: 'nginx'
    static_configs:
      - targets: ['localhost:443/metrics']
EOL

    # Reload Prometheus with the new configuration
    systemctl restart prometheus
else
    echo "Prometheus scraping configuration for NGINX is already set up, skipping."
fi

# Print success message
echo "NGINX, Prometheus, and Grafana setup completed successfully!"
