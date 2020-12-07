Encoding.default_external = 'utf-8'

require 'selenium-webdriver'
require 'ffi'

driver = Selenium::WebDriver.for :firefox # ブラウザ起動
driver.get('https://www3.nhk.or.jp/news/') # URLを開く
# driver.switch_to.frame(1)               # 1つめの子フレームに移動
# driver.switch_to.frame("frameid")       # フレームのnameを指定して移動

p driver

inputElement = driver.find_element(:xpath, "//ul[@class='nav-inner']")
aElement = inputElement.find_elements(:tag_name, "a")
aElement.each do |a|
    p a.text + ", " + a.attribute('href')
end

# driver.navigate.to(aElement[0].attribute('href')) 
driver.get(aElement[3].attribute('href'))

sleep 3 #ページを読み込んでから待たないといけない．おそらく先程やっていたclick処理も同様に待たなければ行けなかったと思われる
nextElement = driver.find_element(:tag_name, "article")
p nextElement.text

driver.quit # ブラウザ終了