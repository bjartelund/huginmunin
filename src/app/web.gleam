import cors_builder as cors
import gleam/http
import mist
import wisp.{type Request, type Response}

pub fn middleware(
  req: wisp.Request,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- cors.wisp_middleware(req, cors())
  use req <- wisp.handle_head(req)

  handle_request(req)
}

fn handler(req: Request) -> Response {
  use req <- cors.wisp_middleware(req, cors())
  wisp.ok()
}

fn cors() {
  cors.new()
  |> cors.allow_origin("http://localhost:8000")
  |> cors.allow_origin("http://localhost:1234")
  |> cors.allow_method(http.Get)
  |> cors.allow_method(http.Post)
}
