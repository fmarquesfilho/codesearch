# Usage: $ ruby script.rb [repositories|code|issues|users] [query_string] [OPTIONAL stars|forks|updated] [OPTINAL asc|desc]
require 'httparty'
require 'launchy'
require 'socket'
require 'awesome_print'

params = {}
params[:type]  = ARGV[0]
params[:q]     = ARGV[1]
params[:sort]  = ARGV[2] || ""
params[:order] = ARGV[3] || ""
params[:csv]   = ARGV[4]


if params[:type] == "help"
puts <<EOF
GitHub's search supports a variety of different operations, below is a quick cheat sheet for some of the simplier searches.

Basic Search

This search Finds repositories with...
cat stars:>100  Find cat repositories with greater than 100 stars.
@defunkt  Get all repositories from the user defunkt.
tom location:"San Francisco, CA"  Find all tom users in "San Francisco, CA".
join extension:coffee Find all instances of join in code with coffee extension.
NOT cat Excludes all results containing cat
Repository Search

Repository search will look through the names and descriptions of all the public projects on GitHub. You can also filter the results by:

This search Finds repositories with...
cat stars:>100  Find cat repositories with greater than 100 stars.
@defunkt  Get all repositories from the user defunkt.
pugs pushed:>2013-01-28 Pugs repositories pushed to since Jan 28, 2013.
node.js forks:<200  Find all node.js repositories with less than 200 forks.
jquery size:1024..4089  Find jquery repositories between the sizes 1024 and 4089 kb.
gitx fork:true  Repository search includes forks of gitx.
gitx fork:only  Repository search returns only forks of gitx.
Code Search

The Code search will look through all of the code publicly hosted on GitHub. You can also filter by :

This search Finds repositories with...
install @charles/privaterepo  Find all instances of install in code from the repository charles/privaterepo.
shogun @heroku  Find references to shogun from all public heroku repositories.
join extension:coffee Find all instances of join in code with coffee extension.
system size:>1000 Find all instances of system in code of file size greater than 1000kbs.
examples path:/docs/  Find all examples in the path /docs/.
replace fork:true Search replace in the source code of forks.
Issue Search

Issue search will look through the titles, bodies, and comments of all the public issues on GitHub. You can also filter the results by:

This search Finds issues...
encoding @heroku  Encoding issues across the Heroku organization.
cat state:open  Find cat issues that are open.
strange comments:>42  Issues with more than 42 comments.
hard label:bug  Hard issues labeled as a bug.
author:mojombo  All issues authored by mojombo.
mentions:tpope  All issues mentioning tpope.
assignee:rtomayko All issues assigned to rtomayko.
exception created:>2012-12-31 Created since the beginning of 2013.
exception updated:<2013-01-01 Last updated before 2013.
User Search

The User search will find users with an account on GitHub. You can filter by :

This search Finds repositories with...
fullname:"Linus Torvalds" Find users with the full name "Linus Torvalds".
tom location:"San Francisco, CA"  Find all tom users in "San Francisco, CA".
chris followers:100..200  Find all chris users with followers between 100 and 200.
ryan repos:>10  Find all ryan users with more than 10 repositories.
EOF
exit
end

if params[:type].nil? || params[:q].nil? || !%w[repositories code issues users].include?(params[:type])
  puts "Usage: $ ruby script.rb [repositories|code|issues|users] [query_string] [stars|forks|updated] [asc|desc]"
  puts "Try: ruby script.rb help"
  exit
end

#START OAuth

	client_id = 'd74fcf012a3e382c7fed'
	client_secret = '653999ffa39d81e9ae4b0138d4685045a625d967' 

	#open authorize page
	Launchy.open ('https://github.com/login/oauth/authorize?client_id=' + client_id)

	input = nil

	#start server to get value of code
	puts 'Starting up server...'

	server = TCPServer.new(2000)
	loop do
  	t = Thread.new(server.accept) do |session|
    	puts "[log] Connection from #{session.peeraddr[2]} at #{session.peeraddr[3]}"
   		puts "[log] Got input from client"
    	input = session.gets
    	session.puts "Permissions granted!\nClosing connection.\nBye :)"
    	puts "[log] Closing connection"
    	session.close
  	end
  	t.join()
  	break if !t.status
	end

	code = input.split("?code=")[1].split(" ")[0]

	#get token
	token = HTTParty.post('https://github.com/login/oauth/access_token', 
        :query => {:client_id => client_id, :client_secret => client_secret, :code => code})

#END OAuth

params[:q] = params[:q].gsub(/\s/, '+')

url = "https://api.github.com/search/#{params[:type]}?q=#{params[:q]}"
url += "&sort=#{params[:sort]}"   unless params[:sort].empty?
url += "&order=#{params[:order]}" unless params[:order].empty?
url += "&" + token

headers = { 'Accept' => 'application/vnd.github.preview.text-match+json', 'User-Agent' => 'coopera-codesearch' }

puts "URL: #{url}"
response = HTTParty.get(url, :headers => headers)

ap response

unless params[:csv].nil?
end
