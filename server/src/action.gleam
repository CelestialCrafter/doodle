//// Module for handling interconnected requests and responses

import request.{Status}
import response

type ProcessingError

pub fn error_to_response(error) {
  todo
}

pub fn error_to_string(error) {
  todo
}

pub fn request_to_response(request) {
  let response = case request {
    Status -> response.Status
  }

  Ok(response)
}
