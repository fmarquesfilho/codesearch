#Auxiliar functions for script
require 'csv'

def pagination header
	links = {}
 
	header['link'].split(',').each do |link|
  	link.strip!
  
  	parts = link.match(/<(.+)>; *rel="(.+)"/)
  	links[parts[2]] = parts[1]
	end
	return links
end

def verify_rate_limit header
	if header['x-ratelimit-remaining'].to_i < 2
		wait = Time.at(header['x-ratelimit-reset'].to_i) - Time.now
		puts '[log] Low rate limit, wait ' +  wait.to_s + 'seconds to reset'
		if(wait > 0); sleep(wait) end
	end
end

def process_data type, response, token, params, file
  send("process_data_#{type}".to_sym, response, token, params, file)
end

def process_data_repositories response, token, params, file
	data = []

	response['items'].each do |item|

		data_aux = { 	
      'name' 						=> item['name'],
			'owner'						=> get_user(item['repository']['owner']['login'], token),
			'created_at'			=> item['created_at'],
			'pushed_at' 			=> item['pushed_at'],
			'watchers_count'	=> item['watchers_count'],
			'forks_count' 		=> item['forks_count'],
			'collaborators'		=> get_collaborators(item['repository']['owner']['login'], item['repository']['name'], token),
			'contributors'		=> get_contributors(item['owner']['login'], item['name'], token)
    }

		ap data_aux
		save_in_csv(file, data_aux)
		data << data_aux
	end
end

def process_data_code response, token, params, file
	data = []

	response['items'].each do |item|
		data_repos = get_repos(item['repository']['owner']['login'], item['repository']['name'], token)

		data_aux = {	'name' 							=> item['repository']['name'],
									'owner'							=> get_user(item['repository']['owner']['login'], token),
									'created_at'				=> data_repos['created_at'],
									'pushed_at' 				=> data_repos['pushed_at'],
									'updated_at'				=> data_repos['updated_at'],
									'fork'							=> data_repos['fork'], 
									'language'					=> data_repos['language'], 
									'watchers_count'		=> data_repos['watchers_count'],
									'forks_count' 			=> data_repos['forks_count'],
									'open_issues_count'	=> data_repos['open_issues_count'],
									'collaborators'			=> get_collaborators(item['repository']['owner']['login'], item['repository']['name'], token),
									'contributors'			=> get_contributors(item['repository']['owner']['login'], item['repository']['name'], token)}
		
		ap data_aux
		save_in_csv(file, data_aux)
		data << data_aux	
	end
end

def get_repos login, repos, token
	url = 'https://api.github.com/repos/' + login + '/' + repos
	return get_response(url, token)
end

def get_user login, token
	url = 'https://api.github.com/users/' + login
	response = get_response(url, token)
	return {'name' => response['name'], 'login'=> response['login'], 'email' => response['email'], 'location' => response['location']}
end

def get_contributors owner, repos, token
	url = 'https://api.github.com/repos/' + owner + '/' + repos + '/contributors'
	response = get_response(url, token)
	contributors = []

	response.each do |item|
    begin
      contributors << get_user(item['login'], token)
    rescue Exception => e
      puts e.inspect
    end
	end

	return contributors
end

def get_collaborators owner, repos, token
	url = 'https://api.github.com/repos/' + owner + '/' + repos + '/collaborators'
	response = get_response(url, token)
	collaborators = []

	response.each do |item|
    begin
      collaborators << get_user(item['login'], token)
    rescue Exception => e
      puts e.inspect
    end
	end

	return collaborators
end

def get_response url, token
	headers = { 'Accept' => 'application/vnd.github.preview.text-match+json', 'User-Agent' => 'coopera-codesearch' }
	url += '?' + token

	begin
		response = HTTParty.get(url, headers)
		verify_rate_limit(response.headers)
	rescue Exception => e
		puts e.inspect
	end

	return response
end

def save_csv_head_code file
	head = 'name,owner,string_seargh,created_at,pushed_at,updated_at,fork,language,watchers_count,forks_count,open_issues_count,collaborators,contributors'
	head_for_save = {}
	
	head.split(',').inject(Hash.new{|aa,b| aa[b] = b}) do |aa,b|
		aa[b] = b
		head_for_save = aa
	end

	save_in_csv(file, head_for_save)
end

def save_in_csv file, result
	begin
		CSV.open(file , "ab") do |csv|
    	csv << result.values
		end
	rescue Exception => e
		puts e.inspect
	end
end
