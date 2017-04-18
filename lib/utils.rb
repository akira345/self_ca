class Utils
  def initialize
  end
  def self.delete_file(dirpath)
    if File.exists? dirpath
      FileUtils.rm_r(Dir.glob("#{dirpath}/"), :secure => true)
      Rails.logger.debug "ファイル削除"
    end
  end
  def self.generate_password(size)
             #パスワード生成
    tmp =[]
    tmp = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    password = Array.new(size){tmp[rand(tmp.size)]}.join
    return password
  end
  def self.generate_cert_param(csr)
    cert_param = Hash.new
    cert_param[:type]="server"
    cert_param[:hostname]=csr.hostname
    cert_param[:password]=nil
    cert_param[:cert_dir] = Rails.root.to_s+"/data/#{csr.user_id}/CERT/"
    cert_param[:cert_rsa_key_length]="2048"
    cert_param[:name] = [
      ['C', "#{csr.country}", OpenSSL::ASN1::PRINTABLESTRING],
      ['ST',"#{csr.dn_st}",OpenSSL::ASN1::UTF8STRING],
      ['L',"#{csr.dn_l}",OpenSSL::ASN1::UTF8STRING],
      ['O', "#{csr.dn_o}", OpenSSL::ASN1::UTF8STRING],
      ['OU', "#{csr.dn_ou}", OpenSSL::ASN1::UTF8STRING],
                  ]
    return cert_param
  end
  def self.generate_ca_param(ca)
           #各ファイルの出力先
    ca_param=Hash.new
    #CAファイルの出力先
    ca_param[:CA_dir] = Rails.root.to_s+"/data/#{ca.user_id}/CA/"
    ca_param[:keypair_file] = File.join ca_param[:CA_dir], "private/cakeypair.pem"
    ca_param[:cert_file] = File.join ca_param[:CA_dir], "cacert.pem"
    ca_param[:serial_file] = File.join ca_param[:CA_dir], "serial"
    ca_param[:new_certs_dir] = File.join ca_param[:CA_dir], "newcerts"
    #CAの有効期限
    ca_param[:ca_cert_days] = 5 * 365 # five years
    #CAの鍵長
    ca_param[:ca_rsa_key_length] = 2048
           #発行する証明書の有効期限と鍵の長さ
    ca_param[:cert_days] = 365 # one year
    ca_param[:cert_key_length_min] = 1024
    ca_param[:cert_key_length_max] = 2048
    #CAのDN
    ca_param[:name] = [
      ['C', "#{ca.country}", OpenSSL::ASN1::PRINTABLESTRING],
      ['ST',"#{ca.dn_st}",OpenSSL::ASN1::UTF8STRING],
      ['L',"#{ca.dn_l}",OpenSSL::ASN1::UTF8STRING],
      ['O', "#{ca.dn_o}", OpenSSL::ASN1::UTF8STRING],
      ['OU', "#{ca.dn_ou}", OpenSSL::ASN1::UTF8STRING],
                ]
    #CAのホスト名情報
    ca_param[:hostname] = ca.hostname
    #CAのパスワード
    ca_param[:password] = ca.ca_password
    return ca_param
  end
end
