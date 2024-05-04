# git pull origin main
# source myenv/bin/activate
pkill -f remote-debugging-port # この設定はクローラの方に書く。エラー発生時に到達しない-> 
# google-chrome --remote-debugging-port=9222 --incognito --disable-site-isolation-trials --disable-gpu --window-size=1280,800 --no-sandbox --display=:0.0 --disable-web-security --user-data-dir=/root/users/dogeking &
google-chrome --remote-debugging-port=9222 --disable-site-isolation-trials --disable-gpu --window-size=1280,800 --display=:0.0 --user-data-dir=/root/users/dogeking &
cd /home/smihata/myworkspace/crypto/crypto-faucet-hunter/dogeking
bundle exec ruby dogeking.rb

# sudo shutdown -h now