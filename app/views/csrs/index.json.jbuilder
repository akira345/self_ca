json.array!(@csrs) do |csr|
  json.extract! csr, :id, :user_id, :hostname, :cert_password, :cert_rsa_key_length, :country, :dn_st, :dn_l, :dn_o, :dn_ou
  json.url csr_url(csr, format: :json)
end
