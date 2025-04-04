import gleam/erlang/process.{type Subject}
import gleam/io
import gleam/otp/actor
import gluid

pub type MuninMessage {
  PutLink(String, String)
  FetchLinks(reply_with: Subject(Result(List(String), Nil)), for: String)
}

pub fn new() -> Result(Subject(MuninMessage), actor.StartError) {
  actor.start(Nil, handle_message)
}

pub fn put_link(munin: Subject(MuninMessage), from: String, link: String) {
  actor.send(munin, PutLink(from, link))
}

pub fn fetch_links(
  munin: Subject(MuninMessage),
  for: String,
) -> Result(List(String), Nil) {
  actor.call(munin, FetchLinks(_, for), 10_000)
}

fn handle_message(message: MuninMessage, _: Nil) -> actor.Next(MuninMessage, _) {
  case message {
    PutLink(from, link) -> {
      make_put_link_call(from, link)
      actor.continue(Nil)
    }

    FetchLinks(reply_with, for) -> {
      let links = make_fetch_links_call(for)
      process.send(reply_with, links)
      actor.continue(Nil)
    }
  }
}

fn make_put_link_call(from: String, link: String) {
  io.println("put link from: " <> from <> " link: " <> link)
  io.println("link saved(?) with id " <> gluid.guidv4())
}

fn make_fetch_links_call(for: String) -> Result(List(String), Nil) {
  io.println("fetch links for: " <> for)
  let links = ["link1", "link2", "link3"]
  Ok(links)
}
