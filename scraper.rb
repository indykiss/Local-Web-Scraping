
require 'find'
require 'rubygems'
require 'nokogiri'
require 'sanitize'
require 'csv'

$count = 0

$urls = Array.new

$base_path = "/www.CopyPathAndPasteInQuotes.com" 

def strip_bad_chars(text)
    text.gsub!(/"/, "'");
    text.gsub!(/\u2018/, "'");
    text.gsub!(/[”“]/, '"');
    text.gsub!(/’/, "'");
    return text
end

# Steps for Wed:
# Take the data that is downloaded and move into the folder next here
# Copy path and add it into line 12 
# Maybe look at the weird CSV thing to get a better 
# sheet than "title" and "body"


def clean_body(text)
    text.gsub!(/(\r)?\n/, "
  ");
    text.gsub!(/\s+/, ' ');
  
    # extra muscle, clean up crappy HTML tags and specify what attributes are allowed
    text = Sanitize.clean(text, :elements => ['h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p', 'a', 'b', 'strong', 'em', 'img', 'iframe'],
        :attributes => {
          'a' => ['href', 'title', 'name'],
          'img' => ['src', 'title', 'alt'],
          'iframe' => ['src', 'url', 'class', 'id', 'width', 'height', 'name'],
          },
        :protocols => {
          'a' => {
            'href' => ['http', 'https', 'mailto']
          },
          'iframe' => {
            'src' => ['http', 'https']
          }
        })
  
    # clean start and end whitespace
    text = text.strip;
    return text
end



  def parse_html_files
    Find.find(Dir.getwd) do |file|
      if !File.directory? file and File.extname(file) == '.html'
        # exclude and skip if in a bad directory
        # we may be on an html file, but some we just do not want
        current = File.new(file).path
  
        # open file, pluck content out by its element(s)
        page = Nokogiri::HTML(open(file));
  
        # grab title
        title = page.css('title').text.to_s;
        title = strip_bad_chars(title)
        
        # for page title, destroy any pipes and MS pipes and return the first match
        title.gsub!(/[│,|],{0,}(.*)+/, '')
  
        # grab the body content
        body = page.css('body').to_html
        body = clean_body(body)
        
        # skip bodies that don't have paypal somewhere
        if current.match(/(old|draft|archive)/)
          next
        end
  
        # clean the file path
        path = File.new(file).path
        path.gsub! $base_path, "/"
        
        # if we have content, add this as a page to our page array
        if (body.length > 0) && (body.include? "paypal")
          $count += 1
          puts "Processing " + title
  
          # insert into array
          data = {
            'title' => title,
            'body' => body,
          }
  
          $urls.push data
        end
      end
    end
  
    write_csv($urls)
    report($count)
  end

  def write_csv(posts)
    CSV.open('urls.csv', 'w' ) do |writer|
      writer << ["path", "title", "body"]
      $urls.each do |c|
        writer << [c['path'], c['title'], c['body']]
      end
    end
  end


  def report(count)
    puts "#{$count} html posts were processed to #{Dir.getwd}/urls.csv"
  end

  parse_html_files
