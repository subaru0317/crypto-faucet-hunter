# crypto-faucet-hunter
仮想通貨のファーセットサイトにWeb自動操縦技術でアクセスし、仮想通貨を自動で取得することを目的としたコード。

# chrome option
google-chrome --remote-debugging-port=9222 --incognito --disable-site-isolation-trials

--incognito: シークレットモードで立ち上げ
--headless=new: ヘッドレスで立ち上げ
--disable-site-isolation-trials: これがないとiframe要素が取得できない(サイト分離機能を無効化)https://www.chromium.org/Home/chromium-security/site-isolation/

# setup
sudo apt update
sudo apt install sox
sudo apt install libsox-fmt-mp3
sudo apt install libsphinxbase3