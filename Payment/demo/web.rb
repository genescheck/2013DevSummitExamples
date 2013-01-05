require 'att_wrapper'
require 'data_mapper'
require 'dm-types'
require 'dm-validations'
require 'haml'
require 'htmlentities'
require 'json'
require 'rack'
require 'rexml/document'
require 'sinatra'

set :escape_html => false

STDOUT.sync = true


DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, ENV["DATABASE_URL"] || 'postgres://dm:dm@localhost/payments')

class Payment
  include DataMapper::Resource  
  property :id,               Serial
  property :domain,           String, :length => 64
  property :authCode,         String, :length => 64
  property :txId,             String, :length => 64
  property :merchantTxId,     String, :length => 64
  property :originalTxId,     String, :length => 64
  property :merchantSubscriptionId,     String, :length => 64
  property :txStatus,         String, :length => 64
  property :txType,           String, :length => 64
  property :body,             Json
  property :started_at,       DateTime
  property :refunded_at,      DateTime
  property :notification_at,  DateTime
  
  def to_s
    s = "id: #{id}, domain: #{domain}, authCode: #{authCode}, txId: #{txId}, "
    s << "merchantTxId: #{merchantTxId}, originalTxId: #{originalTxId}, merchantSubscriptionId: #{merchantSubscriptionId}, "
    s << "txStatus: #{txStatus}, txType: #{txType}, "
    s << "started_at: #{started_at}, refunded_at: #{refunded_at}, notification_at: #{notification_at}, "
    s << "body: #{body}"
    s
  end
end

class Notification
  include DataMapper::Resource  
  property :id,                     Serial
  property :notificationId,         String, :length => 64
  property :notificationType,       String, :length => 64
  property :transactionId,          String, :length => 64
  property :originalTransactionId,  String, :length => 64
  property :body,                   Json
  property :received_at,            DateTime
end


DataMapper.finalize

DataMapper.auto_migrate!  #use auto_migrate! to empty the database each time or auto_upgrade! to keep the data

# This creates a wrapper client that is used for all interactions with the API. 
$wrapper = AttWrapper::Client.new(ENV["API_KEY"],ENV["API_SECRET"],["PAYMENT"], ENV["ENDPOINT"] || "https://api.att.com", nil)
begin
  $wrapper.getAccessToken()
rescue
  # Every time a call is made the code will try to get a new access token, so only reporting the error here
  STDERR.puts "Exception trying to get production access token = #{$!}"
end

configure do
  enable :logging, :dump_errors, :raise_errors, :show_exceptions
end

# =========================
# PAYMENTS
# =========================

# A range of prices may be specified 

begin
  $testAmounts = ENV["TEST_AMOUNTS"].split
rescue
  $testAmounts = ["0.99","1.23"]
end

get '/payment' do
  amount = $testAmounts[0]
  $testAmounts.rotate!(1)
  category = 1
  description = "SinglePay #{amount}"
  merchantTransactionId = "T#{Time.now.strftime('%Y%m%d%H%M%S%L')}"
  productId = "SINGLE001"
  redirectUrl = "http://#{request.host}/redirect"

  q = $wrapper.getSinglePayRedirect(amount,category,description,merchantTransactionId,productId,redirectUrl)

  redirect(q.to_s)
end

get '/payment_demo' do
  amount = $testAmounts[0]
  $testAmounts.rotate!(1)
  category = 1
  description = "SinglePay #{amount}"
  merchantTransactionId = "T#{Time.now.strftime('%Y%m%d%H%M%S%L')}"
  productId = "SINGLE002"
  redirectUrl = "http://#{request.host}/redirect"

  q = $wrapper.getSinglePayRedirect(amount,category,description,merchantTransactionId,productId,redirectUrl)

  "<html><body><a href='#{q}'>#{q}</a></body></html>"
end


get '/subscription' do
  amount = $testAmounts[0]
  $testAmounts.rotate!(1)
  category = 1
  description = "Subscription #{amount}"
  merchantTransactionId = "T#{Time.now.strftime('%Y%m%d%H%M%S%L')}"
  productId = "SUB001"
  redirectUrl = "http://#{request.host}/redirect"

  q = $wrapper.getSubscriptionRedirect(amount,category,description,merchantTransactionId,productId,redirectUrl)

  redirect(q.to_s)
end

# This handles redirects back from Payment Consent with an auth code in the URL
get '/redirect' do
  begin
    if params.has_key? 'TransactionAuthCode'
      s = $wrapper.getTransactionStatus('TransactionAuthCode', params['TransactionAuthCode'])

      tx = Payment.create( :domain => request.host, :authCode => params['TransactionAuthCode'], :txId => s["TransactionId"], \
      :merchantTxId => s["MerchantTransactionId"], :txStatus => s["TransactionStatus"], \
      :txType => "SinglePay", :body => s, \
      :started_at => Time.now )

    elsif params.has_key? 'SubscriptionAuthCode'
      s = $wrapper.getSubscriptionStatus('SubscriptionAuthCode', params['SubscriptionAuthCode'])

      tx = Payment.create( :domain => request.host, :authCode => params['SubscriptionAuthCode'], :txId => s["SubscriptionId"], \
      :merchantTxId => s["MerchantTransactionId"], :merchantSubscriptionId => s["MerchantSubscriptionId"], \
      :txStatus => s["SubscriptionStatus"], \
      :txType => "Subscription", :body => s, \
      :started_at => Time.now )

    else
      raise "Unrecognized transaction type"
    end
  rescue Exception => e
    r = "<html><body><h1>Error Handling Redirect#{$!}</h1></body></html>"
    puts "Redirect failed: #{$!}"
    e.backtrace.each { |b| puts b }
  end

  # Display the transaction information
  r = "<html><body><table border=\"1\"><tr><th>Key</th><th>Value</th></tr>"
  begin
    if s.instance_of? String
      r << s
    elsif s.instance_of? Hash
      s.each { |k,v| r << "<tr><td>#{k}</td><td>#{v}</td></tr>"}
      r << %Q|</table><br/><br/><h2><a href='/refund/#{tx.txId}'>Refund</a></h2>|
    end
  rescue Exception => e
    r = "<html><body><h1>Error #{$!}</h1></body></html>"
    puts "Redirect Output failed: #{$!}"
    e.backtrace.each { |b| puts b }
    
  end
  r << "</body></html>"
end

get '/refund/*' do |id|
  begin
    
    r = $wrapper.doRefund(id)

    refundTxId = r["TransactionId"]
    
    recordRefund(id,refundTxId)
  rescue
    puts "Refund Failed: #{id}, #{$!}"
  end
  redirect('/')
end

get '/status/*' do |id|
  begin
    s = $wrapper.getTransactionStatus('TransactionId', id)

    r = "<html><body><table border=\"1\"><tr><th>Key</th><th>Value</th></tr>"

    s.each { |k,v| r << "<tr><td>#{k}</td><td>#{v}</td></tr>"}
    r << %Q|</table><a href='/refund/#{s["TransactionId"]}'>Refund</a></body></html>|
  rescue
    r = "<html><body><h1>Error #{$!}</h1></body></html>"
  end
  r
end

get '/transactions' do
  begin
    haml :transactions, :locals => { :transactions => Payment.all }
  rescue
    r = "<html><body><h1>Error #{$!}</h1></body></html>"
  end
end


# =========================
# LISTENER - listens for POSTS from the API Gateway with notifications of events
# =========================

coder = HTMLEntities.new

get '/notifications' do
  n = Notification.all
  haml :notifications, :locals => { :notifications => n }
end

post '/notifications/*' do |i|
  begin
    b = request.body.read

    doc = REXML::Document.new b

    doc.elements.each ("/hub:notifications/hub:notificationId") do |n| 

      k = n.text
      begin
        notificationText = $wrapper.getNotification(k)

        notification = JSON.parse(notificationText)
        r = notification["GetNotificationResponse"]
        case r["NotificationType"]
        when 'SuccesfulRefund'
          txId = r["RefundTransactionId"]
          origTxId = r["OriginalTransactionId"]
          recordRefund(origTxId,txId)
        when 'CancelSubscription'
          txId = r["OriginalTransactionId"]
          origTxId = nil
        when 'StopSubscription'
          txId = r["OriginalTransactionId"]
          origTxId = nil
        end
        
        n = Notification.create( :notificationType => r["NotificationType"], :notificationId => k, :transactionId => txId,
        :originalTransactionId => origTxId, :body => notificationText, :received_at => Time.now )

        $wrapper.acknowledgeNotification(k)
      rescue Exception => e
        puts "Get Notification Failed: #{e} - Usually this is caused by a duplicate notification"
      end
    end
  rescue
    STDERR.puts "Error! #{$!}"
  end
  
  [202,"Accepted"]
end

# =========================
# MISCELLANEOUS
# =========================


def recordRefund id, refundId

  begin
    origStatus = $wrapper.getTransactionStatus("TransactionId", id)
    
    orig = Payment.first(:txId => id)
  
    refundLocal = Payment.first(:txId => refundId)
  
    if !refundLocal
      refund = $wrapper.getTransactionStatus("TransactionId", refundId)
  
      refundLocal = Payment.create( :domain => request.host, 
        :txId => refund["TransactionId"] || refund["SubscriptionId"], \
        :originalTxId => id, \
        :merchantTxId => refund["MerchantTransactionId"] || origStatus["MerchantTransactionId"], \
        :txStatus => refund["TransactionStatus"] || refund["SubscriptionStatus"], \
        :txType => "REFUND", :body => nil, \
        :started_at => Time.now )
    end
  
    orig.update(:refunded_at => Time.now)

  rescue Exception => e
    puts "recordRefund failed with #{$!}"
  end
end


get '/' do
  haml :index
end
