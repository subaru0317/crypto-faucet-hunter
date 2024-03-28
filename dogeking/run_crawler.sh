# google-chrome --remote-debugging-port=9222 --incognito --disable-site-isolation-trials --disable-gpu --headless=new --window-size=1280,800 &
# google-chrome --remote-debugging-port=9222 --incognito --disable-site-isolation-trials --disable-gpu --headless=new --window-size=1280,800 --disable-default-apps --disable-background-networking &

# git pull origin master

pkill -f remote-debugging-port # この設定はクローラの方に書く。エラー発生時に到達しない
google-chrome --remote-debugging-port=9222 --incognito --disable-site-isolation-trials --disable-gpu --window-size=1280,800 --disable-default-apps --disable-background-networking &
cd /home/smihata/myworkspace/crypto/crypto-faucet-hunter/dogeking
bundle exec ruby main.rb

# sudo shutdown -h now