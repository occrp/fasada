# Fasada - a front-end cache and reverse proxy config

A front-end cache and reverse proxy config, based on `nginx`, with Tor thrown in for good measure.

Please treat this as a blueprint for your deployment.

## Idea

The basic idea is to have a minimal front-end-cache config that can be spun-up (or indeed, that's just running) on a public server and is able to cache and serve a WordPress website effectively.

This includes strict caching of all content, even dynamic one, in a way that takes the load off of the PHP backend, and that is able to serve cached content for a long period of time in case of the backend not being available (due to maintenance or technical problems).

## Operation

Static resources (CSS, JS, images, etc) should be cached for long time (say, 24 hours or more); cookies on such static resources should be ignored.

Public dynamic resources should be cached for a short time (say, 1 minute), cookies should be ignored/removed.

Private dynamic content (admin pages, etc) should not be cached, at all. Ideally, they would be served from a dedicated domain (`admin.example.com`), which would not be cached, but would also be accessible only via a VPN or some such.

## Configuration

[Upstreams](http://nginx.org/en/docs/http/ngx_http_upstream_module.html) configuration should put in [`services/etc/nginx/conf.d/upstreams.conf`](services/etc/nginx/conf.d/upstreams.conf) file, so that tests can make use of them.

## Testing

Automated tests are provided, using [BATS](https://github.com/bats-core/bats-core/) (which is included as a [git submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules)). When deploying Fasada remember to initialized and pull the submodule:

```
git submodule init
git submodule update
```

Once that's done, tests are available via the `./tests/runtests.sh` command. Upon running it will:

1. use `./tests/gentests.sh` to generate upstream-specific tests
1. run them on the host server
1. run them via `docker-compose exec` in the `nginx` container

## Things to consider

**Q: How should we handle apparent `IP:port` clash between the upstream config and `fasada`? There are going to have to be two `nginx` services running on public ports, right?**  
**A**: Two ways to go around it:
 - run them on different IPs;
 - run them on different ports.

The `fasada` will have to run on public `IP` and ports `80` and `443`, no way around it. We're running `nginx` in a `docker` container, and while there is a way to tell `docker-compose` that a certain port should only be exposed on a certain IP, that would require specific configuration for specific hosts (that is, putting specific `IP` addresses in the `docker-compose.yml` file) - something we want to avoid.  
Hence the sane solution is to run `nginx` from `fasada` on ports `80` and `443`, and the `server-config` one on other ports (say, `10080` and `10443`).

**Q: Where should we handle setting cache control headers?**  
**A**: Apparently the right answer is: ["upstream"](https://serversforhackers.com/nginx-caching/).

# Wait, why nginx?

There are software solutions that are hand-crafted to be reverse proxies and front-end-cache solutions, why are we using `nginx`? Well...

Mainly: no time to play with other solutions and learn them, `nginx` does the job well enough.

But we did look at `varnish`, and we found [it does not support SSL and has no intention to](https://www.varnish-cache.org/docs/trunk/phk/ssl_again.html). We would have to run `nginx` *in front* of `varnish` that would then be *in front of* our upstream `nginx` servers. This is madness.

# ToDo

 - This needs to be documented better, both using comments in code, and using this README file, and the one in the `services/etc/nginx` subdirectory.
 - Also, cleanups in the `nginx` config, there is a lot of unnecessary repetition
