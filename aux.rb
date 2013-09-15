require 'launchy'
require 'socket'

def oAuth
  client_id = 'd74fcf012a3e382c7fed'
  client_secret = '653999ffa39d81e9ae4b0138d4685045a625d967' 
  input = nil
  
  Launchy.open ('https://github.com/login/oauth/authorize?client_id=' + client_id)

  server = TCPServer.new(2000)
  loop do
    t = Thread.new(server.accept) do |session|
      input = session.gets
      session.puts "Permissions granted!\nClosing connection.\nBye :)"
      session.close
    end
    t.join()
    break if !t.status
  end

  code = input.split("?code=")[1].split(" ")[0]

  token = HTTParty.post('https://github.com/login/oauth/access_token', 
        :query => {:client_id => client_id, :client_secret => client_secret, :code => code})

	return token 
end
