module NavigationHelper
  NavItem = Struct.new(:label, :path, :icon, :active, keyword_init: true)

  # Itens do menu de cada papel, na ordem em que aparecem na linha lateral e
  # na barra de abas do celular.
  def navigation_items
    section = controller_path

    items = [ NavItem.new(label: "Início", path: root_path, icon: :home, active: section == "home") ]

    if current_user.owner? || current_user.manager?
      items << NavItem.new(label: "Membros", path: members_path, icon: :users, active: section.start_with?("members"))
      items << NavItem.new(label: "Frota", path: vehicles_path, icon: :bus, active: section == "vehicles")
      items << NavItem.new(label: "Rotas", path: routes_path, icon: :route, active: section == "routes")
    end
    if current_user.owner?
      items << NavItem.new(label: "Auditoria", path: audit_logs_path, icon: :audit, active: section == "audit_logs")
    end
    if current_user.student?
      items << NavItem.new(label: "Meu ônibus", path: students_trip_path, icon: :bus, active: section.start_with?("students"))
    end
    if current_user.driver?
      items << NavItem.new(label: "Minha rota", path: drivers_route_path, icon: :route, active: section == "drivers/routes" && action_name != "passengers")
      items << NavItem.new(label: "Passageiros", path: passengers_drivers_route_path, icon: :passengers, active: action_name == "passengers")
      if current_user.driver&.active_trip
        items << NavItem.new(label: "QR code", path: drivers_trip_qr_code_path, icon: :qr, active: section == "drivers/trip_qr_codes")
      end
    end

    items
  end
end
