import gleam/dynamic/decode
import gleam/json

pub type LinkDocument {
  LinkDocument(url: String)
}

pub type LinksResult {
  LinksResult(results: List(LinkDocument))
}

pub fn linkdocument_decoder() -> decode.Decoder(LinkDocument) {
  use url <- decode.field("url", decode.string)
  decode.success(LinkDocument(url))
}

pub fn linkdocument_encoder(link: LinkDocument) {
  json.object([#("url", json.string(link.url))])
}

pub fn links_result_decoder() -> decode.Decoder(LinksResult) {
  use links <- decode.field("Results", decode.list(linkdocument_decoder()))
  decode.success(LinksResult(links))
}
