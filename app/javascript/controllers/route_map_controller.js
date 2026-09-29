import { Controller } from "@hotwired/stimulus"
import * as L from "leaflet"
import { drivingRoute } from "lib/osrm"

// Sem um bundler, os ícones padrão do Leaflet apontam para caminhos
// relativos inexistentes. `Icon.Default` sempre concatena um imagePath
// autodetectado na frente da URL (mesmo se já for absoluta), então usamos
// um `Icon` normal, com as mesmas medidas padrão, apontando pro CDN.
const markerIcon = new L.Icon({
  iconUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
  iconRetinaUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png",
  shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
  iconSize: [ 25, 41 ],
  iconAnchor: [ 12, 41 ],
  popupAnchor: [ 1, -34 ],
  shadowSize: [ 41, 41 ]
})

// Renderiza as paradas de uma rota num mapa Leaflet, em ordem, com o
// trajeto seguindo as ruas de verdade (via OSRM). Se o serviço de rotas
// falhar, cai de volta para uma linha reta entre as paradas. Paradas sem
// coordenadas (endereço não geocodificado) são ignoradas no mapa.
export default class extends Controller {
  static values = { stops: Array }

  async connect() {
    const geocoded = this.stopsValue.filter((stop) => stop.lat && stop.lng)

    if (geocoded.length === 0) {
      this.element.innerHTML = "<p>Nenhuma parada com localização disponível ainda.</p>"
      return
    }

    const map = L.map(this.element).setView([ geocoded[0].lat, geocoded[0].lng ], 13)

    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap contributors"
    }).addTo(map)

    const straightLine = geocoded.map((stop) => [ stop.lat, stop.lng ])

    geocoded.forEach((stop) => {
      L.marker([ stop.lat, stop.lng ], { icon: markerIcon }).addTo(map).bindPopup(`${stop.step}. ${stop.label}`)
    })

    const road = geocoded.length > 1 ? await drivingRoute(geocoded) : null
    const roadPath = road?.path
    const path = roadPath || straightLine

    L.polyline(path, { color: "blue", weight: 4 }).addTo(map)
    map.fitBounds(path)
  }
}
