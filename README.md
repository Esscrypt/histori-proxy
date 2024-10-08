# NGINX Proxy with Prometheus and Grafana Monitoring

This project sets up an NGINX proxy that dynamically routes requests based on the API key, collects Prometheus metrics, and visualizes them in Grafana. This setup is automated using a bash script that installs dependencies, configures NGINX, Prometheus, and Grafana, and applies the necessary settings.

## Prerequisites

- **Ubuntu-based Linux system**
- **PostgreSQL database** with a `users` table containing the `api_key` and `server` fields.
- **SSL Certificates** (optionally created via Certbot).
- A `.env` file and a `api.histori.xyz` NGINX configuration file in the current working directory.

## .env File

The `.env` file should contain your PostgreSQL database connection URL. Here's an example:

## NGINX Configuration (api.histori.xyz)
The api.histori.xyz file should contain your NGINX configuration. Ensure this file exists in your working directory before running the script.

### How to Use the Bash Script
- Step 1: Make the Script Executable
```bash
chmod +x apply_nginx_config.sh
sudo ./apply_nginx_config.sh
```
The script will:

Install necessary dependencies including NGINX, LuaJIT, lua-resty-postgres, Prometheus, and Grafana.
Set up Prometheus and NGINX to collect and serve metrics.
Set up Grafana for visualizing metrics.
Apply the NGINX configuration from the api.histori.xyz file.
Reload the necessary services to apply the new configuration.
### Accessing Services
Grafana: Available at http://localhost:3000. Use the default credentials (admin/admin) to log in.
Prometheus: Available at http://localhost:9090.
NGINX Prometheus Metrics: Accessible locally at http://localhost:443/metrics.
Metrics Tracked

### The setup tracks the following metrics:
- **Number of Requests**: Total requests handled by NGINX.
- **CPU Usage**: Through Grafana with Prometheus.
- **RAM Usage**: Through Grafana with Prometheus.

### Troubleshooting
Ensure the `.env` and `api.histori.xyz` files are present in the working directory.
Use nginx -t to check for configuration issues.
Use systemctl status to check the status of Prometheus, Grafana, and NGINX.