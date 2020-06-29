Encoding.default_external = 'utf-8'

# スクレイピングを行うためのライブラリ
#require 'nokogiri'
require 'mechanize'

# URLに簡単にアクセスできるようにするためのライブラリ
require 'open-uri'

# CSV出力をできるようにするためのライブラリ
require 'csv'


url = 'https://news.livedoor.com/'
max_article_num = 1

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
#各ジャンルのリンクを取得
links = main.search('//nav[@id="globalNav"]/ul')[0]
links.search('a').each do |link|
    count = 0 #1つのジャンルについて何個の記事を取得してきたかカウントする。カウントがmax_article_numに達したら取得を中断
    titles = []
    texts = []

    #「トレンド」以降の記事は例外として弾く
    if link.text == "トレンド" then
        break
    end

    #トップと主要は例外として弾く
    if link.text == "トップ" || link.text == "主要" then
        next
    end

    #記事のジャンルを取得する
    article_genres.push(link.text)
    p link.text

    #トップページから各ジャンル先にアクセス
    href_str = link.attribute('href').value
    page = main.link_with(:href => href_str).click
    page.search('//ul[@class="articleList"]/li/a').each do |node|
        
        #記事タイトルを取得
        title = node.search('h3').text
        titles.push(title)
        p title
    
        #各記事の本文にアクセス
        href_str = node.attribute('href').value
        next_page = page.link_with(:href => href_str).click
        
        #ページ内に「記事読む」リンクが有り、それをクリックする場合
        if next_page.search('div[@class="articleMore"]/a').length == 1 then
            href_str = next_page.search('div[@class="articleMore"]/a').attribute('href').value
            next_page = next_page.link_with(:href => href_str).click
        end
        
        #本文を取得(p,h2タグの中身のみを取得する、稀にp,h2タグで構成されていないページがあり、何も取得されないケースが存在する)
        # text = ""
        # text_ele = next_page.search('span[@itemprop="articleBody"]')
        # text_ele = text_ele.search('h2,p').each do |t|
        #     text += t.text
        # end
        # text = text.delete("\n")
        # texts.push(text)
        # p text

        #本文を取得(テキスト全てを取得する、たまにvarといった想定外の文字列が入る)
        text_ele = next_page.search('span[@itemprop="articleBody"]')
        text = text_ele.text
        text = text.delete("\n")
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
CSV.open("livedoor_news_data.csv", "w") do |csv|
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