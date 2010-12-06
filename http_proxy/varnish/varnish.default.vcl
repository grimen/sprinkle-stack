# sprinkled: varnish.default.vlc v1

backend default {
  .host = "127.0.0.1";
  .port = "8080";
}

sub vcl_recv {
  unset req.http.cookie;
}