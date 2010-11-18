require 'rubygems'
require 'net/imap'
require 'mail'
require 'rest-client'

imap = Net::IMAP.new("imap.gmail.com",993,true)
imap.login "test@rious.org", "p@ssw0rd!"
imap.select 'Inbox'

while true do
  imap.idle do |resp|
    if resp.kind_of?(Net::IMAP::UntaggedResponse) and resp.name == "EXISTS"
      imap.idle_done
      puts "Mailbox now has #{resp.data} messages"
    end
  end
  imap.uid_search(["NOT", "DELETED"]).each do |uid|
    puts "Mail: #{uid}"
    message = imap.uid_fetch(uid,["BODYSTRUCTURE","BODY[]"])
    if(message[0].attr["BODYSTRUCTURE"].multipart?)
      mail = Mail.new(message[0].attr["BODY[]"])
      puts "from: #{mail.from[0]}"
      puts "attachments: #{mail.attachments.length}"
      mail.attachments.each do |attachment|
        puts "Attachment Filename: #{attachment.filename}"
        File.open("holder/#{attachment.filename}","w") do |file|
          file.puts attachment.decoded
        end
        begin
          RestClient.post 'http://localhost:3000/incoming_emails', :userfile => File.new("holder/#{attachment.filename}","rb"), :email => mail.from[0]
        rescue
          puts "Couldn't send it to the server."
        end
      end
    end
    imap.uid_store(uid, "+FLAGS",[:DELETED])
  end
end
  
