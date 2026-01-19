#!/bin/bash
# Directory
#update and install necessary packages
#git clone - Download repository
#python virtual environment setup
#install python dependencies
#run model
#WSGI -> linux systemd service setup
#Nginx -> Linux systemd service setup
# Enable services to start on boot

#!/bin/bash
set -e

APP_DIR="/opt/intent-app"
APP_USER="ubuntu"

apt update -y
apt install -y git python3 python3-venv python3-pip nginx

mkdir -p $APP_DIR
cd $APP_DIR

# Clone repo
git clone https://github.com/yugandhar9786/Intent-classifier-model.git
cd Intent-classifier-model

# Virtualenv
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt gunicorn

# Train model (optional but ok)
python3 model/train.py

# ---------------- SYSTEMD ----------------
cat <<EOF | sudo tee /etc/systemd/system/intent_gunicorn.service
[Unit]
Description=Gunicorn Intent Classifier
After=network.target

[Service]
User=$APP_USER
Group=$APP_USER
WorkingDirectory=$APP_DIR/Intent-classifier-model
Environment="PATH=$APP_DIR/Intent-classifier-model/venv/bin"
ExecStart=$APP_DIR/Intent-classifier-model/venv/bin/gunicorn \
    --workers 3 \
    --bind 127.0.0.1:6000 \
    wsgi:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# ---------------- NGINX ----------------
cat <<EOF | sudo tee /etc/nginx/conf.d/intent_app.conf
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:6000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

# Permissions
sudo chown -R $APP_USER:$APP_USER $APP_DIR

# Start services
sudo systemctl daemon-reload
sudo systemctl enable intent_gunicorn
sudo systemctl restart intent_gunicorn
sudo systemctl restart nginx


