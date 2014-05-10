class CreateCas < ActiveRecord::Migration
  def change
    create_table :cas do |t|
      t.integer :user_id
      t.string :ca_password
      t.string :ca_param
      t.string :hostname
      t.string :domain_name
      t.string :dn_c
      t.string :dn_st
      t.string :dn_l
      t.string :dn_o
      t.string :dn_ou

      t.timestamps
    end
  end
end
