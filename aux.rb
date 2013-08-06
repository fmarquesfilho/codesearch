#Auxiliar functions for script

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

def process_data_repos response, token, params
	data = []
	
	response['items'].each do |item|

		data_aux = { 	'login' 					=> item['owner']['login'],
									'email' 					=> get_email(item['owner']['login'], token),
									'name' 						=> item['name'],
									'string_seargh' 	=> params,
									'created_at'			=> item['created_at'],
									'pushed_at' 			=> item['pushed_at'],
									'watchers_count'	=> item['watchers_count'],
									'forks_count' 		=> item['forks_count'],
									'contributors'		=> get_contributors(item['owner']['login'], item['name'], token)}

		ap data_aux
		data << data_aux
	end

	return data
end

def process_data_code response, token, params
	data = []

	response['items'].each do |item|
		data_repos = get_repos(item['repository']['owner']['login'], item['repository']['name'], token)

		data_aux = { 	'login' 					=> item['repository']['owner']['login'],
									'email' 					=> get_email(item['repository']['owner']['login'], token),
									'name' 						=> item['repository']['name'],
									'string_seargh' 	=> params,
									'created_at'			=> data_repos['created_at'],
									'pushed_at' 			=> data_repos['pushed_at'],
									'watchers_count'	=> data_repos['watchers_count'],
									'forks_count' 		=> data_repos['forks_count'],
									'contributors'		=> get_contributors(item['repository']['owner']['login'], item['repository']['name'], token)}
		
		ap data_aux
		data << data_aux	
	end

	return data
end

def get_repos login, repos, token
	url = 'https://api.github.com/repos/' + login + '/' + repos
	return get_response(url, token)
end

def get_email login, token
	url = 'https://api.github.com/users/' + login
	response = get_response(url, token)
	return response['email']
end

def get_contributors owner, repos, token
	url = 'https://api.github.com/repos/' + owner + '/' + repos + '/contributors'
	response = get_response(url, token)
	contributors = []

	response.each do |item| 
		contributors << {'login' => item['login'], 'email' => get_email(item['login'], token)}
	end

	return contributors
end

def get_response url, token
	headers = { 'Accept' => 'application/vnd.github.preview.text-match+json', 'User-Agent' => 'coopera-codesearch' }
	url += '?' + token

	response = HTTParty.get(url, headers)
	verify_rate_limit(response.headers)

	return response
end
