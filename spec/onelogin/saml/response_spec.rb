require 'spec_helper'
require 'base64'
require 'logger'

describe Onelogin::Saml::Response do
  let(:raw_saml) { File.open(File.dirname(__FILE__) + '/../../fixtures/test4.xml').read }

  let(:settings) do
    settings = Onelogin::Saml::Settings.new
    
    settings.assertion_consumer_service_url   = "http://localhost:3000/auth/authenticate"
    settings.issuer                           = "saml-example" # the name of your application
    settings.idp_sso_target_url               = "http://dev.awesomesauce.com:8080/opensso/SSOPOST/metaAlias/idp"
    settings.idp_cert_fingerprint             = "def18dbed547cdf3d52b627f41637c443045fe33"
    settings.name_identifier_format           = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
    
    settings
  end

  let(:response) do
    response = Onelogin::Saml::Response.new(Base64.encode64(raw_saml))
    response.settings = settings
    #response.logger = Logger.new(STDOUT) # add this line for debugging
    response
  end


  it "should pull attributes from authentication responses" do
    response.attributes["uuid"].should == "3c678d50-c357-012d-1a87-0017f2dcb387"
    response.attributes["name"].should == "happy"
  end

  it "should expose attributes directly on the response object" do
    response["uuid"].should == "3c678d50-c357-012d-1a87-0017f2dcb387"
  end

  it "should validate the document successfully when attributes are present" do
    response.is_valid?.should == true
  end

end
