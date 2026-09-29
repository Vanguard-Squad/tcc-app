const DRIVING_URL = "https://router.project-osrm.org/route/v1/driving"
const WALKING_URL = "https://routing.openstreetmap.de/routed-foot/route/v1/foot"

async function fetchRoute(baseUrl, points) {
  const coordinates = points.map(({ lat, lng }) => `${lng},${lat}`).join(";")

  try {
    const response = await fetch(`${baseUrl}/${coordinates}?overview=full&geometries=geojson`)
    if (!response.ok) return null

    const route = (await response.json()).routes?.[0]
    if (!route) return null

    return {
      path: route.geometry.coordinates.map(([ lng, lat ]) => [ lat, lng ]),
      duration: route.duration,
      distance: route.distance
    }
  } catch {
    return null
  }
}

export const drivingRoute = (points) => fetchRoute(DRIVING_URL, points)
export const walkingRoute = (points) => fetchRoute(WALKING_URL, points)

// Distância em metros entre dois pontos { lat, lng } (fórmula de haversine).
export function haversine(a, b) {
  const rad = (degrees) => (degrees * Math.PI) / 180
  const dLat = rad(b.lat - a.lat)
  const dLng = rad(b.lng - a.lng)
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(rad(a.lat)) * Math.cos(rad(b.lat)) * Math.sin(dLng / 2) ** 2
  return 2 * 6371000 * Math.asin(Math.sqrt(h))
}

// Insere pontos intermediários para que cada segmento tenha no máximo
// `stepMeters`, permitindo simular um deslocamento suave.
export function densify(path, stepMeters) {
  const dense = []

  path.forEach((point, index) => {
    dense.push(point)
    const next = path[index + 1]
    if (!next) return

    const distance = haversine({ lat: point[0], lng: point[1] }, { lat: next[0], lng: next[1] })
    const pieces = Math.floor(distance / stepMeters)
    for (let i = 1; i <= pieces; i++) {
      const ratio = i / (pieces + 1)
      dense.push([ point[0] + (next[0] - point[0]) * ratio, point[1] + (next[1] - point[1]) * ratio ])
    }
  })

  return dense
}
