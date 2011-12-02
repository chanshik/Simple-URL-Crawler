#!/usr/bin/env ruby

require "rubygems"
require "mechanize"
require "fileutils"

class SimpleUrlCrawler
  def initialize
    @mechanize = Mechanize.new
    @mechanize.user_agent = 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_4; en-us) AppleWebKit/533.17.8 (KHTML, like Gecko) Version/5.0.1 Safari/533.17.8'
    
    Random.srand(Time.now.to_i)
    
    @q = Queue.new
  end
  
  def make_result_file(filename = "")
    begin
      @file = File.new(filename, "w")
    rescue Exception => e
      puts "File creation failed."
      exit 1
    end
  end
  
  def make_urls(url_list = [], depth_limit = 5, max_page = 5000)
    @depth_limit = depth_limit
    @max_page = max_page
    @page_count = 0
	@visited = {}
    
    url_list.each do |url|
      @q << {:url => url, :depth => 1}
    end
    
    while !@q.empty? do
      next_target = @q.pop
      
      break if @page_count > @max_page
	  next if @visited[next_target[:url]].nil? == false and @visited[next_target[:url]] == 1
      next if next_target[:depth] > @depth_limit
      
      @file.puts("#{next_target[:url]}")
      @file.flush

      @page_count += 1
      
      puts "Fetching URL @ #{next_target[:url]}"
	  @visited[next_target[:url]] = 1
      
      if Random.rand(10) >= 5
        sleep(0.5)
      end
      
      begin
        @mechanize.get(next_target[:url]) do |page|
          page.links.each do |link|
            href = link.href.to_s
            
            if is_real_link?(href)
              new_depth = next_target[:depth] + 1
              
              @q << {:url => href, :depth => new_depth}
            end
          end
        end
      rescue Exception => e
        puts "Fecthing error."
      end
    end
  end
  
  def normalize(plain_url)
    plain_url
  end
  
  def is_real_link?(link)
    not_real_links = %w[mp3 mp4 wav flac png gif tiff jpeg jpg bmp pcx doc docx ppt pptx xls xlsx fla swf ps ai js css]
    
    not_real_links.each do |ext|
      return false if link.end_with?(ext)
      return false if !link.start_with?("http")
    end
    return true
  end
end

if ARGV.length < 4
  puts "ruby make_simple_urls [output file] [depth limit] [max count] [Seed URLs...]"
  exit 1
end

total_argv_count = ARGV.length
output_file = ARGV[0]
depth_limit = ARGV[1].to_i
max_count = ARGV[2].to_i
seed_urls = ARGV[3..total_argv_count]

crawler = SimpleUrlCrawler.new
crawler.make_result_file(output_file)
crawler.make_urls(seed_urls, depth_limit, max_count)
