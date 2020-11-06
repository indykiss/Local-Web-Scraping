
require 'find'
require 'rubygems'
require 'nokogiri'
require 'sanitize'
require 'csv'

$count = 0

$urls = Array.new

$base_path = "/community.ebay.ca" 


def strip_bad_chars(text)
    text.gsub!(/"/, "'");
    text.gsub!(/\u2018/, "'");
    text.gsub!(/[”“]/, '"');
    text.gsub!(/’/, "'");
    return text
end

def clean_body(text)
    text.gsub!(/(\r)?\n/, "
  ");
    text.gsub!(/\s+/, ' ');
    # Attempt to get rid of false positives from HREFs
    text.gsub!(/-Payments/, ' ');
    text.gsub!(/-payments/, ' ');
    text.gsub!(/Payments-/, ' ');
    text.gsub!(/payments-/, ' ');
    text.gsub!(/.payments/, ' ');
    text.gsub!(/payments./, ' ');
    text.gsub!(/-Payment/, ' ');
    text.gsub!(/-payment/, ' ');
    text.gsub!(/Payment-/, ' ');
    text.gsub!(/payment-/, ' ');
    text.gsub!(/.payment/, ' ');
    text.gsub!(/payment./, ' ');
    text.gsub!(/SellingwithPayments/, ' ');
    text.gsub!(/ManagedPayments/, ' ');
    text.gsub!(/cart.payments./, ' ');
    
  

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
  
        # clean the file path
        path = File.new(file).path
        # path.gsub! $base_path, "/"

        # clean the URL to drop html/ index.html 
        # and to slice off the beginning of the path
        miniPath = path.split("/").slice(6, 20)

        if miniPath[0] == "443"
          miniPath = path.split("/").slice(7, 20)
        end 

        # if miniPath[-1].include?("index.html")
        #   miniPath[-1] = miniPath[-1].gsub("index.html", "")
        # end 

        # if miniPath[-1].include?(".html")
        #   miniPath[-1] = miniPath[-1].gsub(".html", "")
        # end 

        miniPath = miniPath.join("/")

        miniPath.gsub(",", "/")
        miniPath.gsub(" ", "/") 

        url = "https://community.ebay.ca/#{miniPath}"
        
        # added for careers.ebayinc
        def exclude?(string)
          !include?(string)
        end

        # if we have content, add this as a page to our page array
        # skip bodies that don't have paypal somewhere

        # careers-ebayinc. ALL urls have an href with the below so false positives
        #((body.include? "payments") && (body.exclude? "https://www.ebayinc.com/company/managed-payments/"))

        if body.include?("Payments") || body.include?("payments") || 
          body.include?("PayPal") || body.include?("payout") || 
          body.include?("earnings") || body.include?("proceeds") ||
          body.include?("paypal") 

          $count += 1
          puts "Processing " + title
  
          # insert into array
          data = {
            'url' => url,
            'title' => title
          }
  
          $urls.push data
        end
      end
    end
  
    write_csv($urls)
    report($count)
  end

  def write_csv(posts)
    CSV.open('community_ebay_ca.csv', 'w' ) do |writer|
      writer << ["url", "title"]
      $urls.each do |c|
        writer << [c['url'], c['title']]
      end
    end
  end


  def report(count)
    puts "#{$count} html posts were processed to #{Dir.getwd}/community_ebay_ca.csv"
  end

  parse_html_files



         # if current.match(/(old|draft|archive)/)
        #   next
        # end
