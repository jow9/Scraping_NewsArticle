Encoding.default_external = 'utf-8'

# スクレイピングを行うためのライブラリ
require 'nokogiri'

# URLに簡単にアクセスできるようにするためのライブラリ
require 'open-uri'

# CSV出力をできるようにするためのライブラリ
require 'csv'

url_array = ['https://news.google.com/topstories?hl=ja&gl=JP&ceid=JP:ja']

scraping_Data = []
scraping_Data.push([1,2])
scraping_Data.push([4,3])
p scraping_Data[1][0]

=begin
def setup_doc(url)
    charset = 'utf-8'
    html = open(url) { |f| f.read }
    doc = Nokogiri::HTML.parse(html, nil, charset)

    # 豆知識：<br>タグを改行（\n）に変えて置くとスクレイピングしやすくなるらしい
    doc.search('br').each { |n| n.replace("\n") }
    
    doc # 多分これが返り値
end

p url_array[0]
doc = setup_doc(url_array[0])

main_article_titles = [] #メイン(h3)記事のタイトル
main_article_titles_url = [] #メイン(h3)記事のタイトルのurl

#各章のタイトルを取得する
doc.xpath('//h3[@class="ipQwMb ekueJc gEATFF RD0gLb"]/a').each do |node|
    main_article_titles.push(node.text)
    main_article_titles_url.push(node.attribute('href').value)
end

CSV.open("news_data.csv", "w") do |csv|
    csv << ["id", "url", "title"]
    id = 0
    main_article_titles.each do |title|
        csv << [id, main_article_titles_url[id], title]
        id = id + 1
    end
end
=end
