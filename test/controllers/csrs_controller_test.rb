require 'test_helper'

class CsrsControllerTest < ActionController::TestCase
  setup do
    @csr = csrs(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:csrs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create csr" do
    assert_difference('Csr.count') do
      post :create, csr: { cert_password: @csr.cert_password, cert_rsa_key_length: @csr.cert_rsa_key_length, country: @csr.country, dn_l: @csr.dn_l, dn_o: @csr.dn_o, dn_ou: @csr.dn_ou, dn_st: @csr.dn_st, hostname: @csr.hostname, user_id: @csr.user_id }
    end

    assert_redirected_to csr_path(assigns(:csr))
  end

  test "should show csr" do
    get :show, id: @csr
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @csr
    assert_response :success
  end

  test "should update csr" do
    patch :update, id: @csr, csr: { cert_password: @csr.cert_password, cert_rsa_key_length: @csr.cert_rsa_key_length, country: @csr.country, dn_l: @csr.dn_l, dn_o: @csr.dn_o, dn_ou: @csr.dn_ou, dn_st: @csr.dn_st, hostname: @csr.hostname, user_id: @csr.user_id }
    assert_redirected_to csr_path(assigns(:csr))
  end

  test "should destroy csr" do
    assert_difference('Csr.count', -1) do
      delete :destroy, id: @csr
    end

    assert_redirected_to csrs_path
  end
end
