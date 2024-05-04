# crypto-faucet-hunter
仮想通貨のファーセットサイトにWeb自動操縦技術でアクセスし、仮想通貨を自動で取得することを目的としたコード。

# setup
クロールを開始する前に必ず実行する。
```
bash setup.sh
```

# crawl
クロールを開始する。
```
bash run_crawler.sh
```

# chrome option
google-chrome --remote-debugging-port=9222 --incognito --disable-site-isolation-trials

--incognito: シークレットモードで立ち上げ
--headless=new: ヘッドレスで立ち上げ
--disable-site-isolation-trials: これがないとiframe要素が取得できない(サイト分離機能を無効化)https://www.chromium.org/Home/chromium-security/site-isolation/
--disable-gpu: gpu無効化
--window-size=1280,800: windowサイズ
--no-sandbox: セキュリティ？
--display=:0.0 --disable-web-security --user-data-dir=/root/users/dogeking: セキュリティ？ 


