# Motoristas. Cobre: motorista com ônibus na semana toda, com ônibus diferente
# no sábado (ônibus sem rota), com viagem ativa, e sem ônibus nenhum.
company_a = Seeds.data.fetch(:company_a)
company_b = Seeds.data.fetch(:company_b)

jose = Seeds.driver!(email: "motorista@transportes.com", name: "José Motorista", company: company_a,
                     cnpj_license: "12345678900", birthdate: Date.new(1988, 3, 14))
marcos = Seeds.driver!(email: "motorista2@transportes.com", name: "Marcos Motorista", company: company_a,
                       cnpj_license: "12345678911", birthdate: Date.new(1985, 7, 2))
paulo = Seeds.driver!(email: "motorista.livre@transportes.com", name: "Paulo Sem Ônibus", company: company_a,
                      cnpj_license: "12345678922", birthdate: Date.new(1992, 11, 30))
rafael = Seeds.driver!(email: "motorista@campinas.com", name: "Rafael Motorista", company: company_b,
                       cnpj_license: "98765432100", birthdate: Date.new(1990, 1, 20))

Seeds.link_driver!(jose, Seeds.data.fetch(:vehicle_1), WORKDAYS)
Seeds.link_driver!(jose, Seeds.data.fetch(:vehicle_reserve), %w[sabado])
Seeds.link_driver!(marcos, Seeds.data.fetch(:vehicle_2), WORKDAYS)
Seeds.link_driver!(rafael, Seeds.data.fetch(:vehicle_b), WORKDAYS)

Seeds.data.merge!(jose: jose, marcos: marcos, paulo: paulo, rafael: rafael)
