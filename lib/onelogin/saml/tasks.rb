require 'rake'
require 'rake/tasklib'
require 'webrick/ssl'
require 'erb'

module Onelogin
  module Saml
    class SamlTask < Rake::TaskLib
      
      def initialize
        namespace :saml do
          desc "Generate a self-signed certificate public/private key pair."
          task :gen_cert do
            gen_cert
          end

          desc "Generate a Service Provider metadata file from ./config/sp.yml and ./config/saml_certs/saml.cer"
          task :gen_sp_metadata do
            gen_sp_metadata
          end
        end
      end

      private

      def cert_from_filename(cert_file)
        if File.exists?(cert_file)
          cert_text = File.open(cert_file).read
          cert_text.gsub(/-----.* CERTIFICATE-----\n/,"")
        end
      end

      def missing_sp_yaml?
        unless File.exists?("./config/sp.yml")
          puts "No such file: ./config/sp.yml. Exiting."
          return true
        end
      end

      def incomplete_sp_yaml?(issuer, consumer_url, name_id_format, parsed_yaml)
        unless issuer && consumer_url && name_id_format
          needed_keys = ["issuer", "consumer_url", "name_id_format"]
          puts "sp.yml does not include #{(needed_keys - parsed_yaml.keys).join(", ")}, correct before generating metadata"
          return true
        end
      end

      def render_sp_metadata(issuer, consumer_url, name_id_format, cert_text)
        name_id_format = name_id_format.instance_of?(Array) ? name_id_format : [name_id_format]
        template = File.open(File.expand_path("../sp-metadata.xml.erb",__FILE__)).read
        erb = ERB.new(template,0,"%<>>")
        erb.result(binding)        
      end

      def gen_sp_metadata
        return if missing_sp_yaml?
        sp_yaml = File.open("./config/sp.yml").read
        parsed_yaml = YAML::load(sp_yaml)
        issuer = parsed_yaml["issuer"]
        consumer_url = parsed_yaml["consumer_url"]
        name_id_format = parsed_yaml["name_id_format"]
        return if incomplete_sp_yaml?(issuer, consumer_url, name_id_format, parsed_yaml)
        cert_file = parsed_yaml["cert_file"]
        if cert_file
          cert_text = cert_from_filename(cert_file)
        end
        output = render_sp_metadata(issuer, consumer_url, name_id_format, cert_text)
        File.open("./config/sp.xml","w") { |f| f.write output }
        puts "Wrote ./config/sp.xml"
      end
      
      def gen_cert
        mkdir_p './config/saml_certs'
        system 'openssl genrsa -des3 -out ./config/saml_certs/saml.key 1024'
        system 'openssl req -new -x509 -days 1001 -key ./config/saml_certs/saml.key -out ./config/saml_certs/saml.cer'
      end
      
    end
  end
end

Onelogin::Saml::SamlTask.new
