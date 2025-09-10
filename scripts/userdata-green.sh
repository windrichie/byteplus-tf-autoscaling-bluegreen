#!/bin/bash
set -e

# Create log directory for debugging
mkdir -p /var/log/user-data
exec > >(tee /var/log/user-data/user-data.log) 2>&1

echo "Starting user-data script execution at $(date)"

# Optimized package management for faster startup
export DEBIAN_FRONTEND=noninteractive
echo "Updating package lists and installing dependencies..."
# Skip upgrade for faster startup - only update package lists and install what we need
apt-get update && apt-get install -y --no-install-recommends nginx git && apt-get clean || { 
    echo "Failed to update packages or install dependencies"; 
    exit 1; 
}

# Create application directory
mkdir -p /var/www/app || { echo "Failed to create application directory"; exit 1; }

# Configure Nginx - Ubuntu 22.04 specific configuration
cat > /etc/nginx/sites-available/default <<'EOL'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /var/www/app;
    index index.html index.htm;
    
    server_name _;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
EOL

# Get private IP from instance metadata
echo "Fetching instance private IP..."
PRIVATE_IP=$(curl -s http://100.96.0.96/latest/private_ipv4 || echo "Unable to fetch IP")

# Create a basic index file with private IP information
cat > /var/www/app/index.html <<EOL
<!DOCTYPE html>
<html>
<head>
    <title>HELLO from BytePlus - v1.0.1</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 40px;
            line-height: 1.6;
            background-color: #f0fff0;
        }
        h1 {
            color: #228B22;
        }
        .info-box {
            background-color: #e6ffe6;
            border: 2px solid #228B22;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
        }
        .ip-address {
            font-size: 1.2em;
            font-weight: bold;
            color: #006600;
        }
    </style>
</head>
<body>
    <h1>HELLO from BytePlus - v1.0.1 (GREEN Environment)</h1>
    <div class="info-box">
        <p><strong>Server Status:</strong> Up and running on Ubuntu 22.04!</p>
        <p><strong>Private IP Address:</strong> <span class="ip-address">$PRIVATE_IP</span></p>
        <p><strong>Setup Time:</strong> $(date)</p>
        <p><strong>Environment:</strong> Green Deployment</p>
    </div>
</body>
</html>
EOL

# Test Nginx configuration and restart service
echo "Testing Nginx configuration and restarting service..."
nginx -t && systemctl enable nginx && systemctl restart nginx || { 
    echo "Failed to configure or restart Nginx service"; 
    exit 1; 
}

# Add version identifier for blue/green distinction
echo "GREEN ENVIRONMENT - v1.0.1" > /var/www/app/version.txt

echo "User-data script completed successfully at $(date)"