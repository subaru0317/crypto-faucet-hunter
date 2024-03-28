require 'chrome_remote'
# chrome_remoteでのマウス操作用クラス。
class Mouse
  def initialize(chrome)
    @chrome = chrome
    @x = 0
    @y = 0
  end

  def move(x, y, steps = 100)
    1.upto(steps) do |i|
      @chrome.send_cmd(
        'Input.dispatchMouseEvent',
        type:   'mouseMoved',
        button: 'left',
        x:      @x + (x - @x) * (i / steps.to_f),
        y:      @y + (y - @y) * (i / steps.to_f)
      )
    end
    @x = x
    @y = y
  end

  def click(x, y)
    move(x, y, 100)
    down
    sleep(0.002)
    up
  end

  def click_selector(selector)
    x, y = selector_to_xy(selector)
    click(x, y)
  end

  def down
    @chrome.send_cmd(
      'Input.dispatchMouseEvent',
      type:       'mousePressed',
      button:     'left',
      x:          @x,
      y:          @y,
      clickCount: 1
    )
  end

  def up
    @chrome.send_cmd(
      'Input.dispatchMouseEvent',
      type:       'mouseReleased',
      button:     'left',
      x:          @x,
      y:          @y,
    )
  end

  def scroll(x,y)
    @chrome.send_cmd(
      'Input.synthesizeScrollGesture',
      x:          @x,
      y:          @y,
      xDistance:  -x,
      yDistance:  -y
    )
  end

  def selector_to_xy(selector)
    script = <<~JS
      var input = document.querySelector('#{selector}');
      var box = input.getBoundingClientRect();
      JSON.stringify([ box.left, box.right, box.top, box.bottom ]);
    JS
    result = @chrome.send_cmd("Runtime.evaluate", expression: script)
    result_val = result["result"]["value"]
    return nil if result_val.nil?
    left, right, top, bottom = JSON.parse(result_val)
    x = rand(left..right)
    y = rand(top..bottom)
    [x, y]
  end

  def delay
    sleep(rand*3)
    move(rand*50, rand*20)
  end

  def solve_recaptcha(context_datas, selector)
    @chrome.send_cmd('Runtime.enable')
    js = "document.querySelector('#{selector}').name;"
    response = @chrome.send_cmd('Runtime.evaluate', expression: js)
    recaptcha_iframe_tag_name = response['result']['value']
    recaptcha_frame = @chrome.send_cmd('Page.getFrameTree')['frameTree']['childFrames'].find do |child_frame|
      child_frame['frame']['name'] == recaptcha_iframe_tag_name
    end
    recaptcha_context_datas = context_datas.select do |context_data|
      context_data['auxData']['frameId'] == recaptcha_frame['frame']['id']
    end

    # click reCAPTCHA
    click_selector('#g_recaptcha > div > div > iframe')
    delay
    puts "click reCAPTCHA"

    recaptcha_context_datas.each do |recaptcha_context_data|
      # audio button exist?
      response = selector_to_xy(".recaptcha-checkbox-checked")
      break unless response.nil?

      # click audio
      js = 'document.querySelector("#recaptcha-audio-button").click();'
      response = @chrome.send_cmd('Runtime.evaluate', expression: js, contextId: recaptcha_context_data['id'])
      delay
      sleep(5)
      puts "click audio challenge"

      # download mp3
      js = 'document.querySelector(".rc-audiochallenge-tdownload-link").href'
      response = @chrome.send_cmd('Runtime.evaluate', expression: js, contextId: recaptcha_context_data['id'])
      mp3_url = response['result']['value']
      input_file_name = "audio.mp3"
      FileUtils.mv URI.open(mp3_url).path, input_file_name
      delay
      puts "download mp3"

      # convert mp3 to wav
      output_file_name = "audio.wav"
      convert_mp3_to_wav(input_file_name, output_file_name)
      puts "convert mp3 to wav"
      
      # decode wav to text
      pp passcode = `python3 transcription.py`.chomp!
      puts "decode wav to text"

      # submit passcode
      submit(@chrome, passcode, 'audio-response', recaptcha_context_data['id'])
      delay
      puts "submit passcode"

      # click verify
      js = "document.getElementById('recaptcha-verify-button').click();"
      @chrome.send_cmd('Runtime.evaluate', expression: js, contextId: recaptcha_context_data['id'])
      puts "verify"
      
      File.delete(input_file_name)
      File.delete(output_file_name)
      break
    end
  end

  private

  def convert_mp3_to_wav(mp3_file, wav_file)
    system("sox #{mp3_file} #{wav_file}")
    puts "Conversion complete: #{wav_file}"
  rescue => e
    puts "An error occurred: #{e.message}"
  end
end

if __FILE__ == $0
  chrome = ChromeRemote.client
  mouse = Mouse.new(chrome)
  mouse.scroll(0,100)
  mouse.click_selector('input[name=username]')
  str = 'aiueo0@'
  str.each_char do |char|
    chrome.send_cmd('Input.dispatchKeyEvent', type: 'char', text: char)
  end
end
