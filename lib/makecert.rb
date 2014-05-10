require 'openssl'
require 'fileutils'

class Makecert
  def initialize(ca_config)
    @ca_config = ca_config
    create_ca
  end
#自己認証局を作成
  def create_ca
    #すでに作成済みだったら抜ける
    return if File.exists? @ca_config[:CA_dir]
   #CA作成用ディレクトリを作成
    FileUtils.mkdir_p @ca_config[:CA_dir]
    FileUtils.mkdir_p File.join(@ca_config[:CA_dir], 'private')
    FileUtils.chmod( 0700,File.join(@ca_config[:CA_dir], 'private'))
    FileUtils.mkdir_p File.join(@ca_config[:CA_dir], 'newcerts')
    FileUtils.mkdir_p File.join(@ca_config[:CA_dir], 'crl')

       #シリアルファイルを作成
    File.open @ca_config[:serial_file], 'w' do |f| f << '1' end

    Rails.logger.debug "Generating CA keypair" 
       #キーペア作成
    keypair = OpenSSL::PKey::RSA.new @ca_config[:ca_rsa_key_length]
   #CA証明書を作成
    cert = OpenSSL::X509::Certificate.new
    name = @ca_config[:name].dup << ['CN', 'CA']
    cert.subject = cert.issuer = OpenSSL::X509::Name.new(name)
    cert.not_before = Time.now
    cert.not_after = Time.now + @ca_config[:ca_cert_days] * 24 * 60 * 60
    cert.public_key = keypair.public_key
    cert.serial = 0x0
    cert.version = 2 # X509v3
       #拡張領域を定義
    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate = cert
    cert.extensions = [
      ef.create_extension("basicConstraints","CA:TRUE", true),
      ef.create_extension("nsComment","Ruby/OpenSSL Generated Certificate"),
      ef.create_extension("subjectKeyIdentifier", "hash"),
      ef.create_extension("keyUsage", "cRLSign,keyCertSign", true),
          ]
    cert.add_extension ef.create_extension("authorityKeyIdentifier",
                                           "keyid:always,issuer:always")
#署名
    cert.sign keypair, OpenSSL::Digest::SHA1.new

    cb = proc do @ca_config[:password] end
#キーペアをエクスポート
    keypair_export = keypair.export OpenSSL::Cipher.new('AES-256-CBC'), &cb
#ファイルに出力
    Rails.logger.debug "Writing keypair to #{@ca_config[:keypair_file]}" 
    File.open @ca_config[:keypair_file], "w", 0400 do |fp|
      fp << keypair_export
    end

    Rails.logger.debug "Writing cert to #{@ca_config[:cert_file]}" 
    File.open @ca_config[:cert_file], "w", 0644 do |f|
      f << cert.to_pem
    end

    Rails.logger.debug "Done generating certificate for #{cert.subject}" 
  end
#証明書を作成
  def create_cert(cert_config)
    #すでに作成済みだったら抜ける(add)
    file_name = cert_config[:hostname] || cert_config[:user]
    dest = "#{RAILS_ROOT}/cert/" + file_name
#require 'pp'
#pp dest
    return if File.exists? dest
  #add
    cert_keypair = create_key(cert_config)
    cert_csr = create_csr(cert_config, cert_keypair)
    sign_cert(cert_config, cert_keypair, cert_csr)
  end
#鍵を作成
  def create_key(cert_config)
    passwd_cb = nil
    file_name = cert_config[:hostname] || cert_config[:user]
    dest = "#{RAILS_ROOT}/cert/" + file_name
    keypair_file = File.join dest, (file_name + "_keypair.pem")
    FileUtils.mkdir_p dest
    FileUtils.chmod( 0700,dest)

    Rails.logger.debug "Generating RSA keypair" 
    keypair = OpenSSL::PKey::RSA.new cert_config[:cert_rsa_key_length].to_i

    if cert_config[:password].nil? then
      File.open keypair_file, "w", 0400 do |f|
        f << keypair.to_pem
      end
    else
      passwd_cb = proc do cert_config[:password] end
      keypair_export = keypair.export OpenSSL::Cipher.new('AES-256-CBC'),
                                      cert_config[:password]

      Rails.logger.debug "Writing keypair to #{keypair_file}" 
      File.open keypair_file, "w", 0400 do |f|
        f << keypair_export
      end
    end
    return keypair_file
  end
#CSRファイル作成
  def create_csr(cert_config, keypair_file = nil)
    keypair = nil
    file_name = cert_config[:hostname] || cert_config[:user]
    dest = "#{RAILS_ROOT}/cert/" + file_name
    csr_file = File.join dest, "csr_#{file_name}.pem"

    name = cert_config[:name].dup  ####ここをcert_configにする。cert_configにも国情報を渡す。 
    case cert_config[:type]
    when 'server' then
      name << ['OU', 'CA']
      name << ['CN', cert_config[:hostname]]
    when 'client' then
      name << ['CN', cert_config[:user]]
      name << ['emailAddress', cert_config[:email]]
    end
    name = OpenSSL::X509::Name.new name

    if File.exists? keypair_file then
      keypair = OpenSSL::PKey::RSA.new File.read(keypair_file),
                                       cert_config[:password]
    else
      keypair = create_key cert_config
    end

    Rails.logger.debug "Generating CSR for #{name}" 

    req = OpenSSL::X509::Request.new
    req.version = 0
    req.subject = name
    req.public_key = keypair.public_key
    req.sign keypair, OpenSSL::Digest::SHA1.new

    Rails.logger.debug "Writing CSR to #{csr_file}" 
    File.open csr_file, "w" do |f|
      f << req.to_pem
    end

    return csr_file
  end
#署名
  def sign_cert(cert_config, cert_file, csr_file)
#CSRファイルを読み込み
    csr = OpenSSL::X509::Request.new File.read(csr_file)
#ベリファイチェック
    raise "CSR sign verification failed." unless csr.verify csr.public_key
#鍵長チェック
    if csr.public_key.n.num_bits < @ca_config[:cert_key_length_min] then
      raise "Key length too short"
    end

    if csr.public_key.n.num_bits > @ca_config[:cert_key_length_max] then
      raise "Key length too long"
    end
#DNチェック
    if csr.subject.to_a[0, cert_config[:name].size] != cert_config[:name] then
      raise "DN does not match"
    end

    # Only checks signature here.  You must verify CSR according to your
    # CP/CPS.

    # CA setup

    Rails.logger.debug "Reading CA cert from #{@ca_config[:cert_file]}" 
#CAファイル読み込み
    ca = OpenSSL::X509::Certificate.new File.read(@ca_config[:cert_file])
#CAの鍵を読み込み
    Rails.logger.debug "Reading CA keypair from #{@ca_config[:keypair_file]}" 
    ca_keypair = OpenSSL::PKey::RSA.new File.read(@ca_config[:keypair_file]),
                                        @ca_config[:password]
#シリアルを読み込み
    serial = File.read(@ca_config[:serial_file]).chomp.hex
    File.open @ca_config[:serial_file], "w" do |f|
      f << "%04X" % (serial + 1)
    end

    Rails.logger.debug "Generating cert" 
#証明書作成
    cert = OpenSSL::X509::Certificate.new
    from = Time.now
    cert.subject = csr.subject
    cert.issuer = ca.subject
    cert.not_before = from
    cert.not_after = from + @ca_config[:cert_days] * 24 * 60 * 60
    cert.public_key = csr.public_key
    cert.serial = serial
    cert.version = 2 # X509v3

    basic_constraint = nil
    key_usage = []
    ext_key_usage = []

    case cert_config[:type]
    when "ca" then
      basic_constraint = "CA:TRUE"
      key_usage << "cRLSign" << "keyCertSign"
    when "terminalsubca" then
      basic_constraint = "CA:TRUE,pathlen:0"
      key_usage << "cRLSign" << "keyCertSign"
    when "server" then
      basic_constraint = "CA:FALSE"
      key_usage << "digitalSignature" << "keyEncipherment"
      ext_key_usage << "serverAuth"
    when "ocsp" then
      basic_constraint = "CA:FALSE"
      key_usage << "nonRepudiation" << "digitalSignature"
      ext_key_usage << "serverAuth" << "OCSPSigning"
    when "client" then
      basic_constraint = "CA:FALSE"
      key_usage << "nonRepudiation" << "digitalSignature" << "keyEncipherment"
      ext_key_usage << "clientAuth" << "emailProtection"
    else
      raise "unknonw cert type \"#{cert_config[:type]}\""
    end

    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate = ca
    ex = []
    ex << ef.create_extension("basicConstraints", basic_constraint, true)
    ex << ef.create_extension("nsComment",
                              "Ruby/OpenSSL Generated Certificate")
    ex << ef.create_extension("subjectKeyIdentifier", "hash")
    #ex << ef.create_extension("nsCertType", "client,email")
    unless key_usage.empty? then
      ex << ef.create_extension("keyUsage", key_usage.join(","))
    end
    #ex << ef.create_extension("authorityKeyIdentifier",
    #                          "keyid:always,issuer:always")
    #ex << ef.create_extension("authorityKeyIdentifier", "keyid:always")
    unless ext_key_usage.empty? then
      ex << ef.create_extension("extendedKeyUsage", ext_key_usage.join(","))
    end

    if @ca_config[:cdp_location] then
      ex << ef.create_extension("crlDistributionPoints",
                                @ca_config[:cdp_location])
    end

    if @ca_config[:ocsp_location] then
      ex << ef.create_extension("authorityInfoAccess",
                                "OCSP;" << @ca_config[:ocsp_location])
    end
    cert.extensions = ex
#####署名
    cert.sign ca_keypair, OpenSSL::Digest::SHA1.new

    backup_cert_file = @ca_config[:new_certs_dir] + "/cert_#{cert.serial}.pem"
    Rails.logger.debug "Writing backup cert to #{backup_cert_file}" 
    File.open backup_cert_file, "w", 0644 do |f|
      f << cert.to_pem
    end

    # Write cert
    file_name = cert_config[:hostname] || cert_config[:user]
    dest = "#{RAILS_ROOT}/cert/" + file_name
    cert_file = File.join dest, "cert_#{file_name}.pem"
    Rails.logger.debug "Writing cert to #{cert_file}" 
    File.open cert_file, "w", 0644 do |f|
      f << cert.to_pem
    end

    return cert_file
  end

end

