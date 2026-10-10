module RouteMapsHelper
  # Paradas no formato usado pelos mapas, na ordem em que o ônibus passa por
  # elas: na volta, o percurso é feito de trás para frente.
  def route_stops_for_map(stops, direction: nil)
    list = stops.map do |stop|
      { id: stop.id, step: stop.step, label: stop.address.label_with_city, lat: stop.address.latitude, lng: stop.address.longitude }
    end
    direction.to_s == "return" ? list.reverse : list
  end
end
