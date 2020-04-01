require 'openssl'
require 'fileutils'
##
# QuickCert allows you to quickly and easily create SSL
# certificates.  It uses a simple configuration file to generate
# self-signed client and server certificates.
#
# QuickCert is a compilation of NAKAMURA Hiroshi's post to
# ruby-talk number 89917:
#
# http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/89917
#
# the example scripts referenced in the above post, and
# gen_csr.rb from Ruby's OpenSSL examples.
#
# A simple QuickCert configuration file looks like:
#
#   full_hostname = `hostname`.strip
#   domainname = full_hostname.split('.')[1..-1].join('.')
#   hostname = full_hostname.split('.')[0]
#
#   CA[:hostname] = hostname
#   CA[:domainname] = domainname
#   CA[:CA_dir] = File.join Dir.pwd, "CA"
#   CA[:password] = '1234'
#   
#   CERTS << {
#     :type => 'server',
#     :hostname => 'uriel',
#     :password => '5678',
#   }
#   
#   CERTS << {
#     :type => 'client',
#     :user => 'drbrain',
#     :email => 'drbrain@segment7.net',
#   }
#
# This configuration will create a Certificate Authority in a
# 'CA' directory in the current directory, a server certificate
# with password '5678' for the server 'uriel' in a directory
# named 'uriel', and a client certificate for drbrain in the
# directory 'drbrain' with no password.
#
# There are additional SSL knobs you can tweak in the
# qc_defaults.rb file.
#
# To generate the certificates, simply create a qc_config file
# where you want the certificate directories to be created, then
# run QuickCert.
#
# QuickCert's homepage is:
# http://segment7.net/projects/ruby/QuickCert/
# 
# QuickCertを元に作成
#
class Makecert
  def initialize(ca_config)
    @ca_config = ca_config
    create_ca
  end

  # 自己認証局を作成
  def create_ca
    # すでに作成済みだったら抜ける
    return if File.exist? @ca_config[:CA_dir]
    # CA作成用ディレクトリを作成
    FileUtils.mkdir_p @ca_config[:CA_dir]
    FileUtils.mkdir_p File.join(@ca_config[:CA_dir], 'private')
    FileUtils.chmod(0700, File.join(@ca_config[:CA_dir], 'private'))
    FileUtils.mkdir_p File.join(@ca_config[:CA_dir], 'newcerts')
    FileUtils.mkdir_p File.join(@ca_config[:CA_dir], 'crl')

    # シリアルファイルを作成
    File.open @ca_config[:serial_file], 'w' do |f| f << '1' end

    Rails.logger.debug 'Generating CA keypair'
    # キーペア作成
    keypair = OpenSSL::PKey::RSA.new @ca_config[:ca_rsa_key_length]
    # CA証明書を作成
    cert = OpenSSL::X509::Certificate.new
    # CNに"CA"をセット
    name = @ca_config[:name].dup << ['CN', 'CA']
    cert.subject = cert.issuer = OpenSSL::X509::Name.new(name)
    cert.not_before = Time.now
    cert.not_after = Time.now + @ca_config[:ca_cert_days] * 24 * 60 * 60
    cert.public_key = keypair.public_key
    cert.serial = 0x0
    cert.version = 2 # X509v3
    # 拡張領域を定義
    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate = cert
    cert.extensions = [
      # 基本制約の認証局フラグ
      ef.create_extension('basicConstraints', 'CA:TRUE', true),
      # ネットスケープ用コメント。現在は未使用？らしい。
      # ef.create_extension("nsComment","Ruby/OpenSSL Generated Certificate"),
      # サブジェクト鍵識別子   
      ef.create_extension('subjectKeyIdentifier', 'hash'),
      # 鍵用途
      ef.create_extension('keyUsage', 'cRLSign,keyCertSign', true)
    ]
    # 機関鍵識別子
    cert.add_extension ef.create_extension('authorityKeyIdentifier',
                                           'keyid:always,issuer:always')
    # 署名
    cert.sign keypair, OpenSSL::Digest::SHA256.new

    cb = proc do @ca_config[:password] end
    # キーペアをエクスポート
    keypair_export = keypair.export OpenSSL::Cipher.new('AES-256-CBC'), &cb
    # ファイルに出力
    Rails.logger.debug "Writing keypair to #{@ca_config[:keypair_file]}"
    File.open @ca_config[:keypair_file], 'w', 0400 do |fp|
      fp << keypair_export
    end

    Rails.logger.debug "Writing cert to #{@ca_config[:cert_file]}"
    File.open @ca_config[:cert_file], 'w', 0644 do |f|
      f << cert.to_pem
    end

    Rails.logger.debug "Done generating certificate for #{cert.subject}"
  end

  # 証明書を作成
  def create_cert(cert_config)
    # すでに作成済みだったら抜ける
    file_name = cert_config[:hostname]
    dest = cert_config[:cert_dir] + file_name

    return if File.exists? dest
    Rails.logger.debug 'キーペア作成'
    cert_keypair = create_key(cert_config)
    Rails.logger.debug 'CSR作成'
    cert_csr = create_csr(cert_config, cert_keypair)
    Rails.logger.debug '証明書作成'
    sign_cert(cert_config, cert_keypair, cert_csr)
  end
  # 鍵を作成
  def create_key(cert_config)
    passwd_cb = nil
    file_name = cert_config[:hostname]
    dest = cert_config[:cert_dir] + file_name
    keypair_file = File.join dest, (file_name + '_keypair.pem')
    FileUtils.mkdir_p dest
    FileUtils.chmod(0700, dest)

    Rails.logger.debug 'Generating RSA keypair'
    keypair = OpenSSL::PKey::RSA.new cert_config[:cert_rsa_key_length].to_i

    if cert_config[:password].nil?
      File.open keypair_file, 'w', 0400 do |f|
        f << keypair.to_pem
      end
    else
      passwd_cb = proc do cert_config[:password] end
      keypair_export = keypair.export OpenSSL::Cipher.new('AES-256-CBC'),
                                      cert_config[:password]

      Rails.logger.debug "Writing keypair to #{keypair_file}"
      File.open keypair_file, 'w', 0400 do |f|
        f << keypair_export
      end
    end
    return keypair_file
  end
  # CSRファイル作成
  def create_csr(cert_config, keypair_file = nil)
    keypair = nil
    file_name = cert_config[:hostname]
    dest = cert_config[:cert_dir] + file_name
    csr_file = File.join dest, "csr_#{file_name}.pem"

    name = cert_config[:name].dup
    case cert_config[:type]
    when 'server' then
      name << ['OU', 'CA']
      name << ['CN', cert_config[:hostname]]
    end
    name = OpenSSL::X509::Name.new name

    if File.exist? keypair_file
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
    req.sign keypair, OpenSSL::Digest::SHA256.new

    Rails.logger.debug "Writing CSR to #{csr_file}"
    File.open csr_file, 'w' do |f|
      f << req.to_pem
    end

    csr_file
  end
  # 署名
  def sign_cert(cert_config, cert_file, csr_file)
    # CSRファイルを読み込み
    csr = OpenSSL::X509::Request.new File.read(csr_file)
    # ベリファイチェック
    raise 'CSR sign verification failed.' unless csr.verify csr.public_key
    # 鍵長チェック
    if csr.public_key.n.num_bits < @ca_config[:cert_key_length_min]
      raise 'Key length too short'
    end

    if csr.public_key.n.num_bits > @ca_config[:cert_key_length_max]
      raise 'Key length too long'
    end

    # DNチェック
    # 自己証明なのでチェックしない。
    # if csr.subject.to_a[0, cert_config[:name].size] != cert_config[:name] then
    #   raise "DN does not match"
    # end

    # Only checks signature here.  You must verify CSR according to your
    # CP/CPS.

    # CA setup

    Rails.logger.debug "Reading CA cert from #{@ca_config[:cert_file]}"
    # CAファイル読み込み
    ca = OpenSSL::X509::Certificate.new File.read(@ca_config[:cert_file])
    # CAの鍵を読み込み
    Rails.logger.debug "Reading CA keypair from #{@ca_config[:keypair_file]}"
    ca_keypair = OpenSSL::PKey::RSA.new File.read(@ca_config[:keypair_file]),
                                        @ca_config[:password]
    # シリアルを読み込み
    serial = File.read(@ca_config[:serial_file]).chomp.hex
    File.open @ca_config[:serial_file], 'w' do |f|
      f << '%04X' % (serial + 1)
    end

    Rails.logger.debug 'Generating cert'
    # 証明書作成
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
    when 'ca' then
      basic_constraint = 'CA:TRUE'
      key_usage << 'cRLSign' << 'keyCertSign'
    when 'server' then
      basic_constraint = 'CA:FALSE'
      key_usage << 'digitalSignature' << 'keyEncipherment'
      ext_key_usage << 'serverAuth'
    else
      raise "unknonw cert type \"#{cert_config[:type]}\""
    end

    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate = ca
    ex = []
    ex << ef.create_extension('basicConstraints', basic_constraint, true)
    # Netscape用のコメントらしい。今は未使用？？
    # ex << ef.create_extension("nsComment",
    #                          "Ruby/OpenSSL Generated Certificate")
    ex << ef.create_extension('subjectKeyIdentifier', 'hash')
    unless key_usage.empty?
      ex << ef.create_extension('keyUsage', key_usage.join(','))
    end
    # ex << ef.create_extension("authorityKeyIdentifier",
    #                          "keyid:always,issuer:always")
    # ex << ef.create_extension("authorityKeyIdentifier", "keyid:always")
    unless ext_key_usage.empty?
      ex << ef.create_extension('extendedKeyUsage', ext_key_usage.join(','))
    end

    cert.extensions = ex
    # 署名
    cert.sign ca_keypair, OpenSSL::Digest::SHA256.new
    # CA側にバックアップ
    backup_cert_file = @ca_config[:new_certs_dir] + "/cert_#{cert.serial}.pem"
    Rails.logger.debug "Writing backup cert to #{backup_cert_file}"
    File.open backup_cert_file, 'w', 0644 do |f|
      f << cert.to_pem
    end

    # Write cert
    file_name = cert_config[:hostname]
    dest = cert_config[:cert_dir] + '/' + file_name
    cert_file = File.join dest, "cert_#{file_name}.pem"
    Rails.logger.debug "Writing cert to #{cert_file}"
    File.open cert_file, 'w', 0644 do |f|
      f << cert.to_pem
    end

    cert_file
  end
end
