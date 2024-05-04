sudo apt -y update

# ruby環境構築
sudo apt-get -y install ruby-full
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
rbenv install 3.1.3
rbenv global 3.1.3
rbenv rehash
bundle install

# chromeインストール
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb

# soxインストール
sudo apt -y install sox libsox-fmt-mp3 libsphinxbase3

# xvfbインストール
sudo apt -y install xvfb
