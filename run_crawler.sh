git pull origin main
source myenv/bin/activate
pkill -f remote-debugging-port
google-chrome --remote-debugging-port=9222 --disable-site-isolation-trials --disable-gpu --window-size=1280,800 --display=:0.0 --user-data-dir=/root/users/dogeking &
# xvfb-run --server-args="-ac -screen 0 1280x1024x24" google-chrome --remote-debugging-port=9222 --disable-gpu --display=:0.0 --user-data-dir=/root/users/dogeking &
bundle exec ruby dogeking.rb
