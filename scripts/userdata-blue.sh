#!/bin/bash
set -e

# Create log directory for debugging
mkdir -p /var/log/user-data
exec > >(tee /var/log/user-data/user-data.log) 2>&1

echo "Starting user-data script execution at $(date)"

# Update system with Ubuntu 22.04 considerations
export DEBIAN_FRONTEND=noninteractive
echo "Updating package lists..."
apt-get update || { echo "Failed to update package lists"; exit 1; }

echo "Upgrading packages (this may take a while)..."
apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" || { echo "Failed to upgrade packages"; exit 1; }

# Install dependencies with error handling
echo "Installing Nginx and Git..."
apt-get install -y nginx git || { echo "Failed to install required packages"; exit 1; }

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

# Create a basic index file
cat > /var/www/app/index.html <<EOL
<!DOCTYPE html>
<html>
<head>
    <title>BLUE ENVIRONMENT - v1.0.0</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 40px;
            line-height: 1.6;
        }
        h1 {
            color: #0066cc;
        }
    </style>
</head>
<body>
    <h1>BLUE ENVIRONMENT - v1.0.0</h1>
    <p>Server is up and running on Ubuntu 22.04!</p>
    <p>Setup time: $(date)</p>
</body>
</html>
EOL

# Test Nginx configuration - Ubuntu 22.04 specific
echo "Testing Nginx configuration..."
nginx -t || { echo "Nginx configuration test failed"; exit 1; }

# Enable and restart Nginx
echo "Enabling and starting Nginx..."
systemctl enable nginx || { echo "Failed to enable Nginx service"; exit 1; }
systemctl restart nginx || { echo "Failed to restart Nginx service"; exit 1; }

# Add version identifier for blue/green distinction
echo "BLUE ENVIRONMENT - v1.0.0" > /var/www/app/version.txt

echo "User-data script completed successfully at $(date)"