require 'fileutils'
require 'chrome_remote'
require 'open-uri'
require_relative 'mouse.rb'

def submit(chrome, message, selector, context_id=nil)
  chrome.send_cmd('Runtime.enable')
  message.each_char do |c|
    js = "document.getElementById('#{selector}').value += '#{c}'"
    if context_id.nil?
      chrome.send_cmd('Runtime.evaluate', expression: js)
    else
      chrome.send_cmd('Runtime.evaluate', expression: js, contextId: context_id)
    end
    sleep(rand)
  end
end

def goto_url(chrome, url)
  chrome.send_cmd("Page.enable")
  chrome.send_cmd('Page.navigate', url: url)
  chrome.wait_for("Page.loadEventFired")
end

def login(chrome, mouse)
  context_datas = []
  chrome.send_cmd('Runtime.enable')
  chrome.on('Runtime.executionContextCreated') do |params|
    context_datas << params['context']
  end

  goto_url(chrome, 'https://dogeking.io/login.php')

  # cookie?が使える場合、login処理は行わない
  url = get_current_url(chrome)
  return if url == 'https://dogeking.io/games.php'

  # submit E-mail Address
  submit(chrome, @E_MAIL, 'user_email')
  mouse.delay

  # submit Password
  submit(chrome, @PASSWORD, 'password')
  mouse.delay

  mouse.solve_recaptcha(context_datas)

  # click login
  mouse.click_selector('#process_login')
  puts "Login!"
end

def free_spin(chrome, mouse)
  chrome.wait_for("Page.loadEventFired")
  context_datas = []
  chrome.send_cmd('Runtime.enable')
  chrome.on('Runtime.executionContextCreated') do |params|
    context_datas << params['context']
  end

  goto_url(chrome, 'https://dogeking.io/games.php')

  # click spin game
  puts "click spin game"
  mouse.click_selector('.game_name')
  mouse.delay

  mouse.scroll(0, 200)
  mouse.solve_recaptcha(context_datas)

  # click free spin
  puts "click free spin"
  mouse.click_selector('#spin_wheel')
  mouse.delay
end

def spin_roulette(chrome, mouse, bet_coin)
  goto_url(chrome, 'https://dogeking.io/roulette.php')
  mouse.scroll(0, 300)
  sleep(2)

  mouse.click_selector(%Q{.chip[data-coin="#{bet_coin}"]})
  sleep(1)

  mouse.scroll(0, -250)
  sleep(1)

  mouse.click_selector("#even")
  sleep(1)
  mouse.click_selector("#odd")
  sleep(1)

  mouse.click_selector('#auto_bet_tab')
  sleep(1)
  mouse.click_selector('#start_autobet')
end

def get_current_url(chrome)
  js = 'location.href'
  response = chrome.send_cmd('Runtime.evaluate', expression: js)
  response["result"]["value"]
end

if __FILE__ == $0
  @E_MAIL = "m.kurakurakura.s@gmail.com"
  @PASSWORD = "Kantanpass!2024"

  chrome = ChromeRemote.client
  mouse = Mouse.new(chrome)

  login(chrome, mouse)
  free_spin(chrome, mouse)
  # spin_roulette(chrome, mouse, '100000') # default 100000 = 100K
end
# headless modeでspinが獲得できるかを確認する
# エラー発生時Retryするようにコードを変更する
# gcpでcron実行する
# incognitoを使うんではなくて、urlを都度確認して、一発でhttps://dogeking.io/games.phpに入れているならfree_spinのみ、https://dogeking.io/login.phpに行っちゃったならLogin処理が走るようにした方が時間が節約できてお得。