import { Turbo } from "@hotwired/turbo-rails"

// Fila de check-ins que não conseguiram ser enviados por falta de conexão.
// Fica no localStorage do aparelho e é reenviada até o servidor responder:
// ao voltar a internet, ao abrir qualquer página e a cada 15 segundos.
const STORAGE_KEY = "navway:pending-checkins"
const RETRY_INTERVAL_MS = 15_000

let flushing = false

function read() {
  try {
    return JSON.parse(localStorage.getItem(STORAGE_KEY)) || []
  } catch {
    return []
  }
}

function write(items) {
  try {
    if (items.length) localStorage.setItem(STORAGE_KEY, JSON.stringify(items))
    else localStorage.removeItem(STORAGE_KEY)
  } catch {
    // Sem localStorage (modo privado, armazenamento cheio): nada a fazer.
  }
}

function csrfToken() {
  return document.querySelector("meta[name='csrf-token']")?.content
}

// Envia um check-in. Lança erro só quando não há conexão; qualquer resposta do
// servidor (sucesso, QR expirado, etapa já registrada) encerra a tentativa.
async function send({ url, fields }) {
  const body = new FormData()
  for (const [ key, value ] of fields) {
    if (key !== "authenticity_token") body.append(key, value)
  }

  return fetch(url, {
    method: "POST",
    body,
    credentials: "same-origin",
    headers: { "X-CSRF-Token": csrfToken(), "Accept": "text/html" }
  })
}

export function enqueue(item) {
  write([ ...read(), item ])
}

export function pendingCount() {
  return read().length
}

export async function flush() {
  if (flushing || !navigator.onLine) return
  const items = read()
  if (!items.length) return

  flushing = true
  let sent = 0

  try {
    while (read().length) {
      const [ item, ...rest ] = read()
      try {
        await send(item)
      } catch {
        break // continua sem conexão; tenta de novo depois
      }
      write(rest)
      sent++
    }
  } finally {
    flushing = false
  }

  // Atualiza a tela do aluno para mostrar as etapas que acabaram de ser gravadas.
  if (sent && window.location.pathname.startsWith("/aluno")) {
    Turbo.visit(window.location.href, { action: "replace" })
  }
}

window.addEventListener("online", flush)
document.addEventListener("turbo:load", flush)
setInterval(flush, RETRY_INTERVAL_MS)
