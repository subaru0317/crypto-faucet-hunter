require 'chrome_remote'
require 'fileutils'
require 'open-uri'

# chrome_remoteでのマウス操作用クラス。
class Mouse
  def initialize(chrome)
    @chrome = chrome
    @x = 0
    @y = 0
    @chrome.send_cmd('Runtime.enable')
    @chrome.send_cmd('Page.enable')
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

  def selector_to_xy(selector, iframe_selector=nil, context_id=nil)
    result = nil
    if context_id.nil?
      script = <<~JS
        var input = document.querySelector('#{selector}');
        var box = input.getBoundingClientRect();
        JSON.stringify([ box.left, box.right, box.top, box.bottom ]);
      JS
      p result = @chrome.send_cmd("Runtime.evaluate", expression: script)
    else
      # js = "document.querySelector('iframe')"
      # p iframe = @chrome.send_cmd("Runtime.evaluate", expression: js)
      # js = "document.querySelector('iframe').contentWindow"  
      # p iframe = @chrome.send_cmd("Runtime.evaluate", expression: js)
      # js = "document.querySelector('iframe').contentDocument.querySelector('#recaptcha-anchor-label')"  
      # p iframe = @chrome.send_cmd("Runtime.evaluate", expression: js)
      # 考察
      # doge -> recaptchaはwebsecuritydisableが必要
      # iframe最初からならwebsecuritydisable必要ない
      # ドメインをまたぐときはsecurityが必要？contentDocumentの同一オリジンとか詳しく見る
      # どうせならwebsecuritydisableを使わないようにしたい->他のやつイケてるしこれがいけない理由がわからん
      # sandbox必要？
      # 一旦、querySelectorをiframeに固定する？指定した要素が複数あった場合のquerySelectorの挙動を調査する
      # => 文書内の一致する最初のelementを返す。つまり、recaptchav2以外のiframeが存在した場合にOUT
      # iframe問題は解決したが、原因は不明なままである。ここを追求する必要がある
      script = <<~JS
        var input = #{iframe}.contentWindow.document.querySelector('#recaptcha-anchor-label');
        var box = input.getBoundingClientRect();
        JSON.stringify([ box.left, box.right, box.top, box.bottom ]);
      JS
      result = @chrome.send_cmd("Runtime.evaluate", expression: script, contextId: context_id)
    end
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

  def find_selector(chrome, selector)
    element = chrome.send_cmd('DOM.querySelector', {
      nodeId: chrome.send_cmd('DOM.getDocument')['root']['nodeId'],
      selector: selector
    })
  end

  def solve_recaptcha(context_datas)
    sleep 5
    #原因はsleepなしで早すぎたこと？
    #もしくは、iframeの選択を間違えていた
    #少なくとも、最初の画面に出ているI'
    js = %Q{document.querySelector('iframe[title="recaptcha challenge expires in two minutes"]').name;}
    # js = %Q{document.querySelector('iframe[title="reCAPTCHA"]').name;}
    p response = @chrome.send_cmd('Runtime.evaluate', expression: js)
    recaptcha_iframe_tag_name = response['result']['value']
    recaptcha_frame = @chrome.send_cmd('Page.getFrameTree')['frameTree']['childFrames'].find do |child_frame|
      child_frame['frame']['name'] == recaptcha_iframe_tag_name
    end
    recaptcha_context_datas = context_datas.select do |context_data|
      context_data['auxData']['frameId'] == recaptcha_frame['frame']['id']
    end

    p "click reCAPTCHA"
    click_selector_in_iframe("#recaptcha-anchor-label", "iframe[title='reCAPTCHA']")
    sleep 5

    p recaptcha_context_datas

    recaptcha_context_datas.each do |recaptcha_context_data|
      # 動作未確認
      p "audio button exists?"
      js = 'document.querySelector(".recaptcha-checkbox-checked");'
      p response = @chrome.send_cmd('Runtime.evaluate', expression: js, contextId: recaptcha_context_data['id'])
      break unless response["result"]["value"].nil? 

      p "click audio challenge"
      js = 'document.querySelector("#recaptcha-audio-button").click();'
      response = @chrome.send_cmd('Runtime.evaluate', expression: js, contextId: recaptcha_context_data['id'])
      delay
      sleep(5)

      p "download mp3"
      js = 'document.querySelector(".rc-audiochallenge-tdownload-link").href'
      response = @chrome.send_cmd('Runtime.evaluate', expression: js, contextId: recaptcha_context_data['id'])
      mp3_url = response['result']['value']
      input_file_name = "audio.mp3"
      FileUtils.mv URI.open(mp3_url).path, input_file_name
      delay

      p "convert mp3 to wav"
      output_file_name = "audio.wav"
      convert_mp3_to_wav(input_file_name, output_file_name)

      p "decode wav to text"
      pp passcode = `python3 transcription.py`.chomp!

      p "submit passcode"
      submit(@chrome, passcode, 'audio-response', recaptcha_context_data['id'])
      delay

      p "click verify"
      js = "document.getElementById('recaptcha-verify-button').click();"
      @chrome.send_cmd('Runtime.evaluate', expression: js, contextId: recaptcha_context_data['id'])
      
      File.delete(input_file_name)
      File.delete(output_file_name)
      break
    end
  end  
    
  def click_selector_in_iframe(selector, iframe_selector)
    x, y = selector_in_iframe_to_xy(selector, iframe_selector)
    click(x, y)
  end
  
  def selector_in_iframe_to_xy(selector, iframe_selector)
    doc = @chrome.send_cmd('DOM.getDocument', depth: 0)
    iframe_query_result = @chrome.send_cmd('DOM.querySelector', nodeId: doc['root']['nodeId'], selector: iframe_selector)
    return nil if iframe_query_result.nil?
    iframe_description = @chrome.send_cmd('DOM.describeNode', nodeId: iframe_query_result['nodeId'])
    content_doc_remote_object = @chrome.send_cmd('DOM.resolveNode', backendNodeId: iframe_description['node']['contentDocument']['backendNodeId']);
    content_doc_node = @chrome.send_cmd('DOM.requestNode', objectId: content_doc_remote_object['object']['objectId']);
    element_query_result = @chrome.send_cmd('DOM.querySelector', nodeId: content_doc_node['nodeId'], selector: selector);
    return nil if element_query_result.nil?
    node = @chrome.send_cmd('DOM.describeNode', nodeId: element_query_result['nodeId']);
    bounding_box = @chrome.send_cmd('DOM.getBoxModel', nodeId: node['node']['nodeId'], backendNodeId: node['node']['backendNodeId'])
    coordinates = bounding_box['model']['content']
    upper_left_xy = { x: coordinates[0], y: coordinates[1] }
    upper_right_xy = { x: coordinates[2], y: coordinates[3] }
    lower_right_xy = { x: coordinates[4], y: coordinates[5] }
    lower_left_xy = { x: coordinates[6], y: coordinates[7] }
    left, right, top, bottom = upper_left_xy[:x], upper_right_xy[:x], upper_left_xy[:y], lower_left_xy[:y]
    x = rand(left..right)
    y = rand(top..bottom)
    [x, y]
  end

  private

  def convert_mp3_to_wav(mp3_file, wav_file)
    system("sox #{mp3_file} #{wav_file}")
    puts "Conversion complete: #{wav_file}"
  rescue => e
    puts "An error occurred: #{e.message}"
  end

  def submit(chrome, message, selector, context_id=nil)
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
end

if __FILE__ == $0
  chrome = ChromeRemote.client
  context_datas = []
  chrome.send_cmd("Runtime.enable")
  chrome.on('Runtime.executionContextCreated') do |params|
    context_datas << params['context']
  end
  mouse = Mouse.new(chrome)

  chrome.send_cmd("Page.enable")
  chrome.send_cmd('Page.navigate', url: 'https://dogeking.io/login.php')
  chrome.wait_for("Page.loadEventFired")
  
  # mouse.click_selector_in_iframe("#recaptcha-anchor-label", "iframe[title='reCAPTCHA']")
  mouse.solve_recaptcha(context_datas)
end

