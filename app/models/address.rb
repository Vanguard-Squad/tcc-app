class Address < ApplicationRecord
  geocoded_by :geocodable_address
  after_validation :geocode, if: :should_geocode?

  # Empresa a que o endereço pertence (faculdade, parada, aluno...). Fica
  # vazio apenas por um instante no cadastro da própria empresa, que
  # preenche o campo logo após ser criada.
  belongs_to :company, optional: true
  has_one :headquartered_company, class_name: "Company", foreign_key: "address_id", inverse_of: :address
  has_one :college
  has_one :student
  has_many :stops

  validates :street, :number, :neighborhood, :city, :country, :zip_code, presence: true

  def label_with_city
    "#{street}, #{number} - #{city}"
  end

  def geocoded?
    latitude.present? && longitude.present?
  end

  private
    def geocodable_address
      [ "#{street}, #{number}", complement, neighborhood, city, zip_code, country ].compact_blank.join(", ")
    end

    # Geocoding é best-effort: nunca deve bloquear o salvamento do endereço,
    # e não deve repetir a chamada externa a cada save se nada relevante mudou.
    def should_geocode?
      return false if Rails.env.test?

      new_record? || street_changed? || number_changed? || neighborhood_changed? ||
        city_changed? || zip_code_changed? || country_changed?
    end
end
