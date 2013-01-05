require 'helper' 
require "att_wrapper"

class TestAttWrapperPayments < Test::Unit::TestCase
  def test_single_pay
    a = AttWrapper::Client.new("8d126ce0380ede4072d9c196f8883fa4","c3b3d8ee037e9d74",["PAYMENT"], "https://api.att.com/", ENV["TEST_PROXY"])
    
    amount = "1.23"
    category = 1
    description = "description"
    merchantTransactionId = "txid"
    productId = "productid"
    redirectUrl = "http://url"

    q = a.getSinglePayRedirect(amount,category,description,merchantTransactionId,productId,redirectUrl)
    
    assert_not_nil(q)
    
    assert_instance_of(URI::HTTPS,q)
    
    s = q.to_s
    
    assert(s.length > 0)
  end

  def test_redirect_validation
    a = AttWrapper::Client.new("0123456789abcdef0123456789abcdef","0123456789abcdef",["PAYMENT","SMS"])

    amount = "1.23"
    category = 1
    description = "description"
    merchantTransactionId = "txid"
    productId = "productid"
    redirectUrl = "http://url"

    assert_raises(RuntimeError) {  a.getSinglePayRedirect(nil,category,description,merchantTransactionId,productId,redirectUrl) }
    assert_raises(RuntimeError) {  a.getSinglePayRedirect("",category,description,merchantTransactionId,productId,redirectUrl) }

    assert_raises(RuntimeError) {  a.getSinglePayRedirect(amount,0,description,merchantTransactionId,productId,redirectUrl) }
    assert_raises(RuntimeError) {  a.getSinglePayRedirect(amount,"6",description,merchantTransactionId,productId,redirectUrl) }

    assert_raises(RuntimeError) {  a.getSinglePayRedirect(amount,category,nil,merchantTransactionId,productId,redirectUrl) }
    assert_raises(RuntimeError) {  a.getSinglePayRedirect(amount,category,"",merchantTransactionId,productId,redirectUrl) }

    assert_raises(RuntimeError) {  a.getSinglePayRedirect(amount,category,description,nil,productId,redirectUrl) }
    assert_raises(RuntimeError) {  a.getSinglePayRedirect(amount,category,description,"",productId,redirectUrl) }

    assert_raises(RuntimeError) {  a.getSinglePayRedirect(amount,category,description,merchantTransactionId,nil,redirectUrl) }
    assert_raises(RuntimeError) {  a.getSinglePayRedirect(amount,category,description,merchantTransactionId,"",redirectUrl) }

    assert_raises(RuntimeError) {  a.getSinglePayRedirect(amount,category,description,merchantTransactionId,productId,nil) }
    assert_raises(RuntimeError) {  a.getSinglePayRedirect(amount,category,description,merchantTransactionId,productId,"") }


  end
end
