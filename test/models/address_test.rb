require "test_helper"

class AddressTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert addresses(:one).valid?
  end

  test "requires street, number, neighborhood, country and zip_code" do
    address = Address.new
    assert_not address.valid?
    %i[street number neighborhood country zip_code].each do |attribute|
      assert_includes address.errors[attribute], "não pode ficar em branco"
    end
  end
end
