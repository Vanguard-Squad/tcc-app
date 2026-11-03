require "test_helper"

class ContractsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner, @company = create_company_with_owner!
    @manager = create_manager!(company: @company)
    @company.contract_template.attach(fixture_file_upload("signed_contract.pdf", "application/pdf"))
    @student_user = create_student!(company: @company, contract: nil)
    @contract = @student_user.student.current_contract
    @contract.submit!(fixture_file_upload("signed_contract.pdf", "application/pdf"))
  end

  test "manager lists contracts under review" do
    sign_in(@manager)

    get contracts_url
    assert_response :success
    assert_select "td", text: /#{@student_user.name}/
  end

  test "manager approves the contract and the student gets access" do
    sign_in(@manager)

    patch approve_contract_url(@contract)
    assert_redirected_to contracts_path
    assert @contract.reload.approved?
    assert_equal @manager, @contract.reviewed_by

    sign_in(@student_user)
    get root_url
    assert_response :success
  end

  test "rejecting requires a reason that the student sees" do
    sign_in(@manager)

    patch reject_contract_url(@contract), params: { rejection_reason: "" }
    assert_response :unprocessable_entity
    assert @contract.reload.under_review?

    patch reject_contract_url(@contract), params: { rejection_reason: "Arquivo sem assinatura gov.br" }
    assert_redirected_to contracts_path
    assert @contract.reload.rejected?

    sign_in(@student_user)
    get students_contract_url
    assert_select "p", text: "Arquivo sem assinatura gov.br"
  end

  test "manager attaches the company contract template" do
    sign_in(@manager)

    patch template_contracts_url, params: { contract_template: fixture_file_upload("signed_contract.pdf", "application/pdf") }
    assert_redirected_to contracts_path
    assert @company.reload.contract_template.attached?

    get template_contracts_url
    assert_response :success
    assert_equal "application/pdf", response.media_type
  end

  test "contract template must be a PDF" do
    sign_in(@manager)

    original = @company.contract_template.blob
    patch template_contracts_url, params: { contract_template: fixture_file_upload("not_a_contract.txt", "text/plain") }
    assert_redirected_to contracts_path
    assert_equal "O modelo de contrato precisa ser um arquivo PDF", flash[:alert]
    assert_equal original, @company.reload.contract_template.blob
  end

  test "manager views the signed file" do
    sign_in(@manager)

    get file_contract_url(@contract)
    assert_response :success
    assert_equal "application/pdf", response.media_type
  end

  test "contracts from other companies are not reachable" do
    other_owner, _other = create_company_with_owner!
    sign_in(other_owner)

    get contract_url(@contract)
    assert_response :not_found
  end

  test "students cannot review contracts" do
    sign_in(create_student!(company: @company))

    patch approve_contract_url(@contract)
    assert_redirected_to root_path
    assert @contract.reload.under_review?
  end
end
