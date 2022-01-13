sleep 30
su -l ubuntu
touch test.txt
rails -v >> test.txt
rails s -p 3000 -b 0.0.0.0 -d