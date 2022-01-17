#!/bin/bash
sleep 30
echo "\n" >> /home/ubuntu/.bashrc
echo "export DB_PASSWORD=\`aws ssm get-parameters --name DB_PASSWORD --region eu-central-1 --with-decryption --output text --query Parameters[].Value\`" >> /home/ubuntu/.bashrc
echo "export DB_USER=\`aws ssm get-parameters --name DB_USER --region eu-central-1 --output text --query Parameters[].Value\`" >> /home/ubuntu/.bashrc
echo "export DB_URL=\`aws ssm get-parameters --name DB_URL --region eu-central-1 --output text --query Parameters[].Value\`" >> /home/ubuntu/.bashrc
echo "export RAILS_ENV=production" >> /home/ubuntu/.bashrc
su - ubuntu -c "cd /var/www/P161App && rake db:create"
su - ubuntu -c "cd /var/www/P161App && sudo chown -R ubuntu:ubuntu ."
su - ubuntu -c "cd /var/www/P161App && rails assets:precompile"