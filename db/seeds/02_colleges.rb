# Faculdades por empresa. A "UNITRI" existe nas duas empresas com o mesmo CEP:
# o CEP só precisa ser único dentro de cada empresa.
company_a = Seeds.data.fetch(:company_a)
company_b = Seeds.data.fetch(:company_b)

Seeds.data[:unitri_a] = Seeds.college!(
  name: "UNITRI",
  address: Seeds.address!(company: company_a, street: "Avenida Paulista", number: 900, neighborhood: "Bela Vista", city: "São Paulo",
                          zip_code: "01310-100", lat: -23.5654358, lng: -46.6512009)
)

Seeds.data[:horizonte_a] = Seeds.college!(
  name: "Faculdade Horizonte",
  address: Seeds.address!(company: company_a, street: "Alameda Santos", number: 200, neighborhood: "Cerqueira César", city: "São Paulo",
                          zip_code: "01418-000", lat: -23.5709361, lng: -46.6466046)
)

Seeds.data[:unitri_b] = Seeds.college!(
  name: "UNITRI",
  address: Seeds.address!(company: company_b, street: "Avenida Paulista", number: 900, neighborhood: "Bela Vista", city: "São Paulo",
                          complement: "Campus Campinas", zip_code: "01310-100", lat: -23.5654358, lng: -46.6512009)
)
Seeds.data[:tech_b] = Seeds.college!(
  name: "Faculdade Campinas Tech",
  address: Seeds.address!(company: company_b, street: "Avenida Brasil", number: 1000, neighborhood: "Jardim Chapadão", city: "Campinas",
                          zip_code: "13070-178", lat: -22.8956, lng: -47.0562)
)
