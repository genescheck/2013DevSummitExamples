require "json"
require "base64"
require "net/http"
require "uri"

module AttWrapper 

  class Client 

    attr_reader :client_id, :client_secret, :scopes, :access_token, :endpoint_url, :endpoint_host, :endpoint_scheme, :proxy_url, :proxy_port

    # This only assigns values to the appropriate locations.  
    # Call getAccessToken() to pre-populate the access token. 
    # However, an access token will automatically be retrieved before most calls
    
    def initialize(client_id, client_secret, scopes, endpoint_url = "https://api.att.com/", proxy_url = nil)

      raise "client_id must be a 32 character hexadecimal string" if not client_id.instance_of? String or client_id.strip.length != 32 \
      or not /^[0-9a-f]{32}$/ =~ client_id
      raise "client_secret must be a 16 character hexadecimal string" if not client_secret.instance_of? String \
      or client_secret.strip.length < 16 or not /^[0-9a-f]{16}$/ =~ client_secret
      raise "scopes must be a non-empty Array" if not scopes.instance_of?(Array) or scopes.size == 0
      raise "endpoint_url must be a non-empty URL" if !validateString(endpoint_url)

      @client_id = client_id
      @client_secret = client_secret
      @scopes = scopes
      @access_token = nil
      @endpoint_url = endpoint_url

      uri = URI.parse(endpoint_url)

      @endpoint_host = uri.host
      @endpoint_scheme = uri.scheme

      raise "endpoint host must be set" if !validateString(@endpoint_host)
      raise "endpoint scheme must be set" if !validateString(@endpoint_scheme)

      if( proxy_url != nil && proxy_url.strip.length > 0)
        uri = URI.parse(proxy_url)
        @proxy_url = uri.host
        @proxy_port = uri.port
      else
        @proxy_url = nil
        @proxy_port = nil
      end

    end

    def to_s
      "client_id=#{@client_id}, client_secret=#{@client_secret}, scopes=#{@scopes}, endpoint_url=#{@endpoint_url}"
    end

##########################
# OAUTH
##########################

    # The APIs use the client_credentials and authorization_code grant types.  
    # The authorization_code grant type uses a browser redirect to get user authentication and consent
    # This method creates the URL for the redirect.
    def getAuthCodeUrl(scopes)
      raise "Authorization code requests require at least one scope" if scopes.length == 0
      URI::HTTPS.build(:host => "api.att.com", :path => "/oauth/authorize", :query => "client_id=#{client_id}&scope=#{scopes.join(',')}")
    end

    def getAuthCodeToken(code)

      raise "Auth code tokens require a valid authorization code" if !validateString(code)

      uri = URI::HTTPS.build({:host => @endpoint_host, :path => "/oauth/token"})

      request = Net::HTTP::Post.new( uri.request_uri, 
      initheader = {'Content-Type' => 'application/x-www-form-urlencoded'})

      request.body = "client_id=#{@client_id}&client_secret=#{@client_secret}&grant_type=authorization_code&code=#{code}"

      resp = JSON.parse(doHttpRequest(uri,request).body)

      resp["access_token"]
    end


    def getAccessToken()

      return @access_token if @access_token != nil

      uri = URI::HTTPS.build({:host => @endpoint_host, :path => "/oauth/token"})

      request = Net::HTTP::Post.new( uri.request_uri, 
      initheader = {'Content-Type' => 'application/x-www-form-urlencoded'})

      request.body = "client_id=#{@client_id}&client_secret=#{@client_secret}&grant_type=client_credentials&scope=#{scopes.join(',')}"

      resp = JSON.parse(doHttpRequest(uri,request).body)

      @access_token = resp["access_token"]
    end

##########################
# PAYMENT
##########################

    def getSinglePayRedirect(amount,category,description,merchantTransactionId,productId,redirectUrl)
      raise "amount must be a positive decimal number" if amount == nil \
      or not /^[0-9]{1,2}.[0-9]{2}$/ =~ amount

      raise "category must be a number between 1 and 5, except 2" if category == nil \
      or !(category.instance_of? Integer or category.instance_of? Fixnum) \
      or category < 1 or category > 5 or category == 2

      raise "description must be a non-empty string" if not validateString(description)

      raise "merchantTransactionId must be a unique value" if not validateString(merchantTransactionId)

      raise "productId must be a non-empty string" if not validateString(productId)

      raise "redirectUrl must be a non-empty string" if not validateString(redirectUrl)

      s = {
        "Amount" => amount,
        "Category" => category,
        "Channel" => "MOBILE_WEB",
        "Description" => description,
        "MerchantTransactionId" => merchantTransactionId,
        "MerchantProductId" => productId,
        "MerchantPaymentRedirectUrl" => redirectUrl
      }.to_json

      resp = doPost( "/Security/Notary/Rest/1/SignedPayload", s, "application/json", "application/json")

      parsed_notary = JSON.parse(resp)

      signedDocument = parsed_notary["SignedDocument"]

      URI::HTTPS.build({:host => @endpoint_host, :path => "/rest/3/Commerce/Payment/Transactions", :query => "Signature=#{parsed_notary["Signature"]}&SignedPaymentDetail=#{parsed_notary["SignedDocument"]}&clientid=#{@client_id}"})

    end

    def getSubscriptionRedirect(amount,category,description,merchantTransactionId,productId,redirectUrl)
      raise "amount must be a positive decimal number" if amount == nil \
      or not /^[0-9]{1,2}.[0-9]{2}$/ =~ amount

      raise "category must be a number between 1 and 5, except 2" if category == nil \
      or !(category.instance_of? Integer or category.instance_of? Fixnum) \
      or category < 1 or category > 5 or category == 2

      raise "description must be a non-empty string" if not validateString(description)

      raise "merchantTransactionId must be a unique value" if not validateString(merchantTransactionId)

      raise "productId must be a non-empty string" if not validateString(productId)

      raise "redirectUrl must be a non-empty string" if not validateString(redirectUrl)

      s = {
        "Amount" => amount,
        "Category" => category,
        "Channel" => "MOBILE_WEB",
        "Description" => description,
        "MerchantTransactionId" => merchantTransactionId,
        "MerchantProductId" => productId,
        "MerchantPaymentRedirectUrl" => redirectUrl,
        "MerchantSubscriptionIdList" => merchantTransactionId[-12..-1], # must be unique
        "IsPurchaseOnNoActiveSubscription" => "false", # Only use false
        "SubscriptionRecurrences" => 99999, # Only use 99999
        "SubscriptionPeriod" => "MONTHLY", # Only use MONTHLY 
        "SubscriptionPeriodAmount" => 1  # Only use 1
        }.to_json

        resp = doPost( "/Security/Notary/Rest/1/SignedPayload", s, "application/json", "application/json")

        parsed_notary = JSON.parse(resp)

        signedDocument = parsed_notary["SignedDocument"]

        URI::HTTPS.build({:host => @endpoint_host, :path => "/rest/3/Commerce/Payment/Subscriptions", :query => "Signature=#{parsed_notary["Signature"]}&SignedPaymentDetail=#{parsed_notary["SignedDocument"]}&clientid=#{@client_id}"})

      end

      def doRefund( id, reasonText = "Customer was not happy" )

        getAccessToken if @access_token == nil

        uri = URI.parse("#{@endpoint_url}/rest/3/Commerce/Payment/Transactions/#{id}?Action=refund")

        request = Net::HTTP::Put.new( uri.request_uri, 
        initheader = { 'Content-type' => 'application/json', 'Accept' => 'application/json', 'Authorization' => "Bearer #{access_token}" })

        request.body = %Q[{ "TransactionOperationStatus":"Refunded","RefundReasonCode":1,"RefundReasonText":"#{reasonText}" }]

        JSON.parse(doHttpRequest(uri,request).body)
      end


      def getTransactionStatus( idType, id )

        raise "Invalid idType" if !["TransactionId","TransactionAuthCode","MerchantTransactionId"].include?(idType)

        getAccessToken if @access_token == nil

        uri = URI.parse("#{@endpoint_url}/rest/3/Commerce/Payment/Transactions/#{idType}/#{id}")

        request = Net::HTTP::Get.new( uri.request_uri, 
        initheader = { 'Accept' => 'application/json', 'Authorization' => "Bearer #{access_token}" })

        JSON.parse(doHttpRequest(uri,request).body)
      end

      def getSubscriptionStatus( idType, id )

        raise "Invalid idType" if !["SubscriptionId","SubscriptionAuthCode","MerchantTransactionId"].include?(idType)

        getAccessToken if @access_token == nil

        uri = URI.parse("#{@endpoint_url}/rest/3/Commerce/Payment/Subscriptions/#{idType}/#{id}")

        request = Net::HTTP::Get.new( uri.request_uri, 
        initheader = { 'Accept' => 'application/json', 'Authorization' => "Bearer #{access_token}" })

        JSON.parse(doHttpRequest(uri,request).body)
      end


      def getNotification( id )

        getAccessToken if @access_token == nil

        uri = URI::HTTPS.build(:host => @endpoint_host, :path => "/rest/3/Commerce/Payment/Notifications/#{id}")

        request = Net::HTTP::Get.new( uri.request_uri, 
        initheader = { 'Accept' => 'application/json', 'Authorization' => "Bearer #{access_token}" })

        resp = doHttpRequest(uri,request)
        body = resp.body
        body
      end


      def acknowledgeNotification( id )

        getAccessToken if @access_token == nil

        uri = URI::HTTPS.build(:host => @endpoint_host, :path => "/rest/3/Commerce/Payment/Notifications/#{id}")

        request = Net::HTTP::Put.new( uri.request_uri, 
        initheader = { 'Authorization' => "Bearer #{access_token}" })

        request.body= ''

        response = doHttpRequest(uri,request)

        response.body
      end


##########################
# UTILS
##########################

      def doPost(path, payload, contentType, accept)

        uri = URI.parse("#{@endpoint_url}#{path}")

        request = Net::HTTP::Post.new( uri.request_uri, 
        initheader = {'Content-Type' => contentType, 
          'Accept' => accept,
          'client_id' => @client_id,
          'client_secret' => @client_secret
          }
        )

        request.body = payload

        doHttpRequest(uri,request).body
      end

      def doHttpRequest( uri, request )
        if( @proxy_url != nil )
          resp = Net::HTTP::Proxy(@proxy_url, @proxy_port).start(uri.host, 
          uri.port, 
          :use_ssl => true, 
          :verify_mode => OpenSSL::SSL::VERIFY_NONE ) do |http|
            http.request(request)
          end
        else
          resp = Net::HTTP.start(uri.host, 
          uri.port, 
          :use_ssl => true, 
          :verify_mode => OpenSSL::SSL::VERIFY_NONE ) do |http|
            http.request(request)
          end
        end
      end

      def validateString( s )
        s != nil and s.instance_of? String and s.length > 1
      end
    end
  end
