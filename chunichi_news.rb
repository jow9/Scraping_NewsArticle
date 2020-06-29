Encoding.default_external = 'utf-8'

# スクレイピングを行うためのライブラリ
#require 'nokogiri'
require 'mechanize'

# URLに簡単にアクセスできるようにするためのライブラリ
require 'open-uri'

# CSV出力をできるようにするためのライブラリ
require 'csv'


url = 'https://www.chunichi.co.jp/'
max_article_num = 4

agent = Mechanize.new #agent:ブラウザのようなもの
agent.max_history = 2 #キャッシュの保存量の設定 デフォルトでは無限に保存する
agent.user_agent_alias = 'Windows Firefox' #User Agentを設定
agent.conditional_requests = false #キャッシュに存在するページへの再アクセス時に更新チェックを行うかどうかの設定。デフォルトではtrue


p url

article_genres = [] #記事のジャンル
article_titles = [] #記事のタイトル
article_texts = [] #記事の本文

main = agent.get(url) #トップページ

#各トピックの記事にアクセス（トピックはヘッダーの「ニュース」より取得する）
links = main.search('//div[@class="link-list-wrap"]')[0]
links.search('a[@class="link-list-lv2-item-link"]').each do |link|
    count = 0 #1つのジャンルについて何個の記事を取得してきたかカウントする。カウントがmax_article_numに達したら取得を中断
    titles = []
    texts = []

    #天気以降の記事は例外として弾く
    if link.text == "天気" then
        break
    end

    #記事のジャンルを取得する
    article_genres.push(link.text)
    p link.text

    #トップページから各ジャンル先にアクセス
    href_str = link.attribute('href').value
    page = main.link_with(:href => href_str).click
    page.search('p[@class="detail-ttl"]/a').each do |node|
        
        #記事タイトルを取得
        title = node.text.delete("\n")
        title = node.text.delete("\t")
        titles.push(title)
        p node.text
    
        #各記事の本文にアクセス
        href_str = node.attribute('href').value
        next_page = page.link_with(:href => href_str).click
        text_ele = next_page.search('div[@id="entry"]/div[@class="block"]')
    
        #本文を取得
        text = ""
        text_ele.first(text_ele.size - 1).each do |next_node|
            text += next_node.text
        end
        text = text.delete("\t")
        texts.push(text)
        p text
    
        #カウントがmax_article_numに達したら記事取得を中断
        count += 1
        if count > max_article_num then
            break
        end

        sleep 1 #読み込み速度を調整してリンク先への負荷を軽減
    end

    #1つのジャンル内にある複数記事のタイトルと本文をリストに保存
    article_titles.push(titles)
    article_texts.push(texts)
end


#CSVに出力
id = 0
p article_genres.size
CSV.open("chunichi_news_data.csv", "w") do |csv|
    csv << ["id", "genre", "title", "text"]
    i = 0
    article_genres.each do |genre|
        for j in 0..max_article_num do
            csv << [id, genre, article_titles[i][j], article_texts[i][j]]
            j += 1
            id += 1
        end
        i += 1
    end
end