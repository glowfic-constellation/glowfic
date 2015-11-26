#!/usr/bin/env ruby

def write_page(file, page)
  evenc = '#E3E3E3'
  oddc = '#D1D1D1'
  response = HTTParty.get('http://tvtropes.org/pmwiki/posts.php?discussion=5dt6ub9yrpgzcwi5gjw1r0mf&page='+page.to_s)
  html_doc = Nokogiri::HTML(response.body)
  headers = html_doc.css('.forumreplyheader')
  replies = html_doc.css('.forumreplybody')

  headers.each_with_index do |header, index|
    reply = replies[index]
    links = header.css('a')
    comment_text = reply.css('.forumtext').inner_html
    comment_user = links[1].inner_html
    comment_time = links[2].inner_html
    color = (index % 2 == 0 ? evenc : oddc)
    file.puts("<div style='background-color:#{color};width:100%;padding:20px;'><b>")
    file.puts(comment_user+"<br>")
    file.puts(comment_time+"</b><br><br>")
    file.puts(comment_text)
    file.puts("</div>")
  end
end

File.open('./luminosityscrape.html', 'w') do |file|
  file.puts("<html><head /><body style='padding:0px;margin:0px;'>")
  (1..108).each do |page|
    write_page(file, page)
    file.puts("")
  end
  file.puts("</body></html>")
end
