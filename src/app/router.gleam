import app/web
import gleam/dynamic/decode
import gleam/erlang/process.{type Subject}
import gleam/http.{Get, Post}
import gleam/result
import gleam/string
import gleam/string_tree
import link_document.{LinkDocument}
import munin.{type MuninMessage}
import wisp.{type Request, type Response}

pub fn handle_request(req: Request) -> Response {
  use req <- web.middleware(req)

  // Wisp doesn't have a special router abstraction, instead we recommend using
  // regular old pattern matching. This is faster than a router, is type safe,
  // and means you don't have to learn or be limited by a special DSL.
  //
  case wisp.path_segments(req) {
    // This matches `/`.
    [] -> home_page(req)

    // This matches `/comments`.
    ["links"] -> links(req)

    // This matches all other paths.
    _ -> wisp.not_found()
  }
}

fn home_page(req: Request) -> Response {
  // The home page can only be accessed via GET requests, so this middleware is
  // used to return a 405: Method Not Allowed response for all other methods.
  use <- wisp.require_method(req, Get)

  let html = string_tree.from_string("Hello World!")
  wisp.ok()
  |> wisp.html_body(html)
}

fn links(req: Request) -> Response {
  // This handler for `/comments` can respond to both GET and POST requests,
  // so we pattern match on the method here.

  let assert Ok(munin) = munin.new()

  case req.method {
    Get -> list_links(munin)
    Post -> create_links(munin, req)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

fn list_links(munin: Subject(MuninMessage)) -> Response {
  // In a later example we'll show how to read from a database.
  let assert Ok(links) = munin.fetch_links(munin, "Bjarte")
  let delimited = string.join(links, ",")

  let html = string_tree.from_string(delimited)
  wisp.ok()
  |> wisp.html_body(html)
}

fn create_links(munin: Subject(MuninMessage), req: Request) -> Response {
  // In a later example we'll show how to parse data from the request body.

  use body <- wisp.require_json(req)
  let link_result = decode.run(body, link_document.linkdocument_decoder())

  let link = result.unwrap(link_result, LinkDocument("N/A"))

  munin.put_link(munin, "Bjarte", link.url)
  let html = string_tree.from_string(link.url)

  wisp.created()
  |> wisp.html_body(html)
}
