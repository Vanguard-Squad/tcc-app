require "test_helper"

module Students
  class ContractsControllerTest < ActionDispatch::IntegrationTest
    setup do
      _owner, @company = create_company_with_owner!
      @student_user = create_student!(company: @company, contract: nil)
    end

    test "first login sends the student to the contract page" do
      post login_url, params: { email: @student_user.email, password: RegistrationTestHelpers::PASSWORD }
      assert_redirected_to students_contract_path
    end

    test "student without an approved contract cannot use the rest of the system" do
      sign_in(@student_user)

      get root_url
      assert_redirected_to students_contract_path
      get students_trip_url
      assert_redirected_to students_contract_path
    end

    test "student can still log out before the contract is approved" do
      sign_in(@student_user)

      delete logout_url
      assert_redirected_to login_path
    end

    test "downloads the contract filled with the student data" do
      sign_in(@student_user)

      get download_students_contract_url
      assert_response :success
      assert_equal "application/pdf", response.media_type
      assert response.body.start_with?("%PDF")
    end

    test "uploading the signed PDF puts the contract under review" do
      sign_in(@student_user)

      patch students_contract_url, params: { contract: { signed_file: fixture_file_upload("signed_contract.pdf", "application/pdf") } }

      assert_redirected_to students_contract_path
      contract = @student_user.student.reload.contract
      assert contract.under_review?
      assert contract.signed_file.attached?
      assert Log.exists?(action: "contract.submitted", auditable: contract)

      get root_url
      assert_redirected_to students_contract_path
    end

    test "rejects files that are not PDF" do
      sign_in(@student_user)

      patch students_contract_url, params: { contract: { signed_file: fixture_file_upload("not_a_contract.txt", "text/plain") } }

      assert_response :unprocessable_entity
      assert @student_user.student.reload.contract.pending?
    end

    test "student cannot resend while the contract is under review" do
      sign_in(@student_user)
      @student_user.student.current_contract.submit!(fixture_file_upload("signed_contract.pdf", "application/pdf"))

      patch students_contract_url, params: { contract: { signed_file: fixture_file_upload("signed_contract.pdf", "application/pdf") } }
      assert_redirected_to students_contract_path
      assert_equal "Seu contrato já foi enviado.", flash[:alert]
    end

    test "student with an approved contract uses the system normally" do
      @student_user.student.current_contract.update!(status: :approved)
      sign_in(@student_user)

      get root_url
      assert_response :success
    end
  end
end
