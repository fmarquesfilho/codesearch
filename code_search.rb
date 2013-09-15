require 'httparty'
require 'csv'
require_relative 'aux'

print "STARTED AT " + Time.now.strftime('%H:%M:%S')
print "\n"

if ARGV[0].nil?
  puts "Usage: $ ruby script_name.rb querystring"
  puts "Try: ruby script.rb help"
  exit
end

STDOUT.sync = true
BASE_URL    = "https://api.github.com/"
TOKEN       = oAuth 
HEADERS     = {
  'Accept'     => 'application/vnd.github.preview.text-match+json',
  'User-Agent' => 'coopera-codesearch'
}

q = ARGV[0].gsub(/\s/, '+')
filename = q.gsub(/\//, '\\')

CSV.open("#{filename}.csv", "w") do |csv|
  csv << %w{owner name watchers forks issues created_at update_at}
end

for page in 1..10
  url = BASE_URL + "search/code?q=#{q}"
  url+= "&" + TOKEN
	url += "&per_page=100&page=#{page}"

  response = HTTParty.get(url, :headers => HEADERS)
  results = response['items']

  unless results.nil?
    results.each_with_index do |res, ind|
      temp = {}
      temp.merge!({:owner => res['repository']['owner']['login']})
      temp.merge!({:name  => res['repository']['name']})

      repo_url = BASE_URL + "repos/#{res['repository']['full_name']}?" + TOKEN

      repo_res = HTTParty.get(repo_url, :headers => HEADERS)
      
			print "CURRENT PAGE: %02d/10 CURRENT REPO: %04d/1000" % [page, (page-1)*100+(ind+1)]
      print "\r"

      temp.merge!({:watchers   => repo_res['watchers_count'] })      
      temp.merge!({:forks      => repo_res['forks_count'] })      
      temp.merge!({:issues     => repo_res['open_issues_count'] })      
      temp.merge!({:created_at => repo_res['created_at'] })      
      temp.merge!({:updated_at => repo_res['updated_at'] })      

      CSV.open("#{filename}.csv", "a") { |csv| csv << temp.values }
    end
  end

  break if response.headers['link'].nil?
end

print "\n"
print "FINISHED AT " + Time.now.strftime('%H:%M:%S')
print "\n"
