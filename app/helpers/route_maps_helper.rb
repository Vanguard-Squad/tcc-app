module RouteMapsHelper
  # Paradas no formato usado pelos mapas, na ordem em que o ônibus passa por
  # elas: na volta, o percurso é feito de trás para frente.
  def route_stops_for_map(stops, direction: nil)
    list = stops.map do |stop|
      { id: stop.id, step: stop.step, label: stop.address.label_with_city, lat: stop.address.latitude, lng: stop.address.longitude }
    end
    # `trip.direction` devolve a chave do enum ("return_trip"); o valor gravado é "return".
    Trip.directions.fetch(direction.to_s, direction.to_s) == "return" ? list.reverse : list
  end
end
