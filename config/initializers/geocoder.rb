# O Nominatim (OpenStreetMap) exige um User-Agent identificável e rejeita
# o padrão do Ruby com 403. https://operations.osmfoundation.org/policies/nominatim/
Geocoder.configure(
  http_headers: { "User-Agent" => "TccApp/1.0 (projeto acadêmico)" },
  timeout: 5
)
