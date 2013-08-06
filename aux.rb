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

def process_data_repos response, token, headers, params
	data = []
	
	response['items'].each do |item|

		data_aux = { 	'login' 					=> item['owner']['login'],
									'email' 					=> get_email(item['owner']['login'], token, headers),
									'name' 						=> item['name'],
									'string_seargh' 	=> params,
									'created_at'			=> item['created_at'],
									'pushed_at' 			=> item['pushed_at'],
									'watchers_count'	=> item['watchers_count'],
									'forks_count' 		=> item['forks_count'],
									'contributors'		=> get_contributors(item['owner']['login'], item['name'], token, headers)}

		data << data_aux
	end

	return data
end

def process_data_code response, token, headers, params
	data = []

	response['items'].each do |item|
		data_repos = get_repos(item['repository']['owner']['login'], item['repository']['name'], token, headers)

		data_aux = { 	'login' 					=> item['repository']['owner']['login'],
									'email' 					=> get_email(item['repository']['owner']['login'], token, headers),
									'name' 						=> item['repository']['name'],
									'string_seargh' 	=> params,
									'created_at'			=> data_repos['created_at'],
									'pushed_at' 			=> data_repos['pushed_at'],
									'watchers_count'	=> data_repos['watchers_count'],
									'forks_count' 		=> data_repos['forks_count'],
									'contributors'		=> get_contributors(item['repository']['owner']['login'], item['repository']['name'], token, headers)}

		data << data_aux	
	end

	return data
end

def get_repos login, repos, token, headers
	url = 'https://api.github.com/repos/' + login + '/' + repos
	url += '?' + token

	response = HTTParty.get(url, :headers => headers)
	return response
end

def get_email login, token, headers
	url = 'https://api.github.com/users/' + login
	url += '?' + token

	response = HTTParty.get(url, :headers => headers)
	return response['email']
end

def get_contributors owner, repos, token, headers
	url = 'https://api.github.com/repos/' + owner + '/' + repos + '/contributors'
	url += '?' + token

	contributors = []
	response = HTTParty.get(url, headers)

	response.each do |item| 
		contributors << {'login' => item['login'], 'email' => get_email(item['login'], token, headers)}
	end

	return contributors
end
