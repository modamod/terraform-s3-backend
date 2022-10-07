#!/bin/bash

amazon-linux-extras  install -y   epel
yum install -y git

python3 -m pip install -U pip
python3 -m pip install -U wheel
python3 -m pip install -U ansible

cd /home/ec2-user && git clone https://www.github.com/modamod/sample-flask-app.git
python3 -m venv /home/ec2-user/sample-flask-app/venv

chown -R ec2-user:ec2-user sample-flask-app
cd sample-flask-app && ansible-playbook playbook.yaml
