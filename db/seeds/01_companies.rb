# Empresas (multi-empresa: cada uma enxerga só os próprios dados), donos e
# secretarias.
#
# Empresa A: cenário principal, São Paulo.
# Empresa B: prova o isolamento entre empresas, Campinas.

# --- Empresa A ---
owner_a = Seeds.user!(email: "dona@transportes.com", name: "Maria Dona", role: :owner)
company_a = Company.find_or_initialize_by(cnpj: "12345678000199").tap do |company|
  company.assign_attributes(
    name: "Transportes Escolares Ltda", owner: owner_a,
    address: Seeds.address!(company: company.persisted? ? company : nil, street: "Avenida Paulista", number: 1000, neighborhood: "Bela Vista", city: "São Paulo",
                            zip_code: "01310-100", lat: -23.5648865, lng: -46.651918)
  )
  company.save!
end
owner_a.update!(company: company_a)
Seeds.user!(email: "secretaria@transportes.com", name: "Secretaria da Empresa", role: :manager, company: company_a)

# --- Empresa B ---
owner_b = Seeds.user!(email: "dono@campinas.com", name: "Carlos Dono", role: :owner)
company_b = Company.find_or_initialize_by(cnpj: "98765432000155").tap do |company|
  company.assign_attributes(
    name: "Viação Campinas Escolar", owner: owner_b,
    address: Seeds.address!(company: company.persisted? ? company : nil, street: "Rua Conceição", number: 200, neighborhood: "Centro", city: "Campinas",
                            zip_code: "13010-050", lat: -22.9035, lng: -47.0620)
  )
  company.save!
end
owner_b.update!(company: company_b)
Seeds.user!(email: "secretaria@campinas.com", name: "Secretaria Campinas", role: :manager, company: company_b)

# --- Dono que ainda não cadastrou a empresa (cai no cadastro de empresa ao entrar) ---
Seeds.user!(email: "novo.dono@transportes.com", name: "Novo Dono", role: :owner)

Seeds.data.merge!(company_a: company_a, company_b: company_b)
