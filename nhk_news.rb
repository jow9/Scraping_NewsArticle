Encoding.default_external = 'utf-8'

require 'selenium-webdriver'
require 'ffi'
require 'csv' # CSV出力ライブラリ

driver = Selenium::WebDriver.for :firefox # ブラウザ起動

driver.get('https://www3.nhk.or.jp/news/') # NHKニュースサイトを開く
tab_element = driver.find_element(:xpath, "//ul[@class='nav-inner']")
genre_link_elements = tab_element.find_elements(:tag_name, "a")

genre_titles = [] #存在するジャンル名
genre_links = [] #ジャンルページへのリンク

article_genres = [] #記事のジャンル
article_titles = [] #記事のタイトル
article_texts = [] #記事の本文
article_imgs = [] #記事の関連画像

#各ジャンルページへのリンクを抽出
genre_link_elements.each do |link_element|
    
    #「地域」以降の記事は例外として弾く
    if link_element.text == "地域" then
        break
    end

    #トップと主要は例外として弾く
    if link_element.text == "新着" then
        next
    end

    genre_titles << link_element.text
    genre_links << link_element.attribute('href')
    p link_element.text + " : " + link_element.attribute('href')
end

#記事データを抽出
genre_number = 0
genre_links.each do |link|
    driver.get(link)
    sleep 2 #ロードを待つ

    #記事リスト
    article_element_list = driver.find_elements(:xpath, "//main[@id='main']/article[@class='module module--list-items']/section/div/ul/li")
    
    #記事リストから各記事のリンクを抽出
    article_link_list = []
    article_element_list.each do |article_element|
        article_link_list << article_element.find_element(:xpath, "dl/dd/a").attribute('href')
    end
    
    article_link_list.each do |article_link|
        driver.get(article_link)
        sleep 2

        begin
            section_element = driver.find_element(:xpath, "//article[@class='module module--detail--v3']/section")
        rescue => error
            next
        end
        
        #記事ジャンルを登録
        article_genres << genre_titles[genre_number]

        #タイトルを抽出
        article_titles << section_element.find_element(:xpath, "header/div/h1/span").text
        p article_titles.last

        #要約を抽出
        summry_text = "<p>" + section_element.find_element(:xpath, "section/div/p").text + "</p>"

        #本文を抽出
        maintext = ""
        maintext_element_list = section_element.find_elements(:xpath, "section/div/div/section")
        if maintext_element_list.each do |maintext_element|
            
            begin
                maintext += "<section><h2>" + maintext_element.find_element(:tag_name, "h2").text + "</h2>"
            rescue => error
                maintext += "<section>"
                p "<section>にタイトルはありません"
            end

            begin
                maintext += "<div>" + maintext_element.find_element(:tag_name, "div").text + "</div></section>"
            rescue => error
                maintext += "</section>"
                p "<section>に本文はありません"
            end

        end.empty?
            p "要約文のみ"
        end
        article_texts << summry_text + maintext #要約＋本文
        p article_texts.last

        # 画像を抽出
        begin
            article_imgs << section_element.find_element(:tag_name, "img").attribute('src')
            p article_imgs.last
        rescue
            article_imgs << ""
            p "画像はありません"
        end
    end

    genre_number += 1
end

driver.quit # ブラウザ終了

#CSVに出力
id = 0
CSV.open("nhk_news_data.csv", "w") do |csv|
    csv << [] #"id", "genre", "title", "imgsrc", "text"
    
    article_genres.each do |genre|
        csv << [id, genre, article_titles[id], article_imgs[id], article_texts[id]]
        id += 1       
    end
end