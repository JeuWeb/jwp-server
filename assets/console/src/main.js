import { Socket } from 'phoenix/assets/js/phoenix.js'
import LiveSocket from 'phoenix_live_view'
import NProgress from 'nprogress'

const csrfToken = document
  .querySelector('meta[name="csrf-token"]')
  .getAttribute('content')

const liveSocket = new LiveSocket('/lv/console', Socket, {
  params: { _csrf_token: csrfToken },
})

window.addEventListener('phx:page-loading-start', _ => NProgress.start())
window.addEventListener('phx:page-loading-stop', _ => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
liveSocket.enableDebug()
// liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket
