import app/router
import gleam/erlang/process
import gleam/list
import mist
import munin
import wisp

pub fn main() {
  io.println("Hello from huginmunin!")
  let assert Ok(munin) = munin.new()
  munin.put_link(munin, "Bjarte", "https://google.com")
  let assert Ok(links) = munin.fetch_links(munin, "Bjarte")
  list.each(links, io.println)

  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let assert Ok(_) =
    wisp_mist.handler(router.handle_request, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}
