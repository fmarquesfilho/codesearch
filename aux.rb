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
