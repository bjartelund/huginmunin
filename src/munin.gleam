import gleam/erlang/process.{type Subject}
import gleam/http.{Get, Http, Put}
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/io
import gleam/json
import gleam/list
import gleam/otp/actor
import gleam/result
import gluid
import link_document.{LinkDocument}

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

fn construct_document(from: String, link: String) {
  json.object([
    #("url", json.string(link)),
    #("owner", json.string(from)),
    #("@metadata", json.object([#("@collection", json.string("Links"))])),
  ])
}

fn make_put_link_call(from: String, link: String) -> Nil {
  io.println("put link from: " <> from <> " link: " <> link)
  let id = from <> gluid.guidv4()

  let document_string = construct_document(from, link) |> json.to_string

  let req =
    request.new()
    |> request.set_scheme(http.Http)
    |> request.set_host("brave_leakey:8080")
    |> request.set_path("/databases/Munin/docs?id=" <> id)
    |> request.set_body(document_string)
    |> request.set_method(Put)

  let resp = httpc.send(req)
  case resp {
    Ok(_) -> io.println("link saved(?) with id " <> id)
    Error(_) -> io.println("failed to save link: ")
  }
  Nil
}

fn make_fetch_links_call(for: String) -> Result(List(String), Nil) {
  io.println("fetch links for: " <> for)

  let req =
    request.new()
    |> request.set_scheme(http.Http)
    |> request.set_host("brave_leakey:8080")
    |> request.set_path("/databases/Munin/docs?startsWith=" <> for)
    |> request.set_method(Get)

  let resp = httpc.send(req)

  case resp {
    Ok(body) -> {
      io.println("response body: " <> body.body)
      let json_value =
        json.parse(body.body, link_document.links_result_decoder())

      case json_value {
        Ok(parsed_json) ->
          Ok(parsed_json.results |> list.map(fn(link) { link.url }))
        Error(_) -> Error(Nil)
      }
    }
    Error(_) -> Error(Nil)
  }
}
