import gleam/io
import gleam/list
import munin

pub fn main() {
  io.println("Hello from huginmunin!")
  let assert Ok(munin) = munin.new()
  munin.put_link(munin, "from Bjarte", "link to google")
  let assert Ok(links) = munin.fetch_links(munin, "from Bjarte")
  list.each(links, io.println)
}
