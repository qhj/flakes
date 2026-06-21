import { Resolver } from 'node:dns/promises'
import { readFile, writeFile } from 'node:fs/promises'
import https from 'node:https'
import { parseArgs } from 'node:util'

function get(ip: string, hostname: string, pathname: string) {
  const { promise, resolve, reject } = Promise.withResolvers<string>()
  const req = https.request(
    {
      hostname: ip,
      port: 443,
      path: pathname,
      method: 'GET',
      headers: {
        Host: hostname,
      },
    },
    (res) => {
      let data = ''
      res.setEncoding('utf8')
      res.on('data', (chunk) => (data += chunk))
      res.on('end', () => resolve(data))
    },
  )
  req.on('error', reject)
  req.end()

  return promise
}

const {
  values: {
    'url-file': urlFile,
    'output-file': outputFile,
    'ips-file': ipsFile,
  },
} = parseArgs({
  args: process.argv.slice(2),
  options: {
    'url-file': {
      type: 'string',
      short: 'u',
    },
    'output-file': {
      type: 'string',
      short: 'o',
    },
    'ips-file': {
      type: 'string',
      short: 'i',
    },
  },
})

if (!urlFile || !outputFile || !ipsFile) {
  process.exit(1)
}

const url = (await readFile(urlFile, { encoding: 'utf8' })).trim()

const [prefix] = url.split('.json')
if (!prefix) {
  console.error('invalid url')
  process.exit(1)
}

const { hostname } = new URL(url)
const resolver = new Resolver()
resolver.setServers(['223.5.5.5'])
const address = await resolver.resolve4(hostname)
const ip = address[0]

if (!ip) {
  console.error('filter query dns record')
  process.exit(1)
}

const directIps = (await readFile(ipsFile, { encoding: 'utf8' }))
  .trim()
  .split(/[\s,]+/)

const urls = [url]
urls.push(
  ...Array.from({ length: 5 }).map((_, i) => {
    return `${prefix + (i + 2)}.json`
  }),
)

const list = await Promise.all(
  urls.map((u) => {
    const { pathname } = new URL(u)
    return get(ip, hostname, pathname)
  }),
)

const outboundsByRegion = list.reduce((acc, jsonStr) => {
  const config = JSON.parse(jsonStr) as {
    outbounds: { type: string; tag: string }[]
  }
  const outbounds = config.outbounds.filter(
    ({ type }) =>
      type !== 'selector' &&
      type !== 'urltest' &&
      type !== 'block' &&
      type !== 'direct',
  )

  outbounds.forEach((o) => {
    const index = o.tag.lastIndexOf(' ')
    if (index !== -1) {
      const region = o.tag.slice(0, index)
      const regionOutbounds = acc.get(region)
      if (regionOutbounds) {
        regionOutbounds.push(o)
      } else {
        acc.set(region, [o])
      }
    }
  })

  return acc
}, new Map<string, object[]>())

const nodes = [...outboundsByRegion].flatMap(([region, outbounds]) => {
  return outbounds.map((o, i) => {
    return { ...o, tag: `${region}${(i + 1).toString().padStart(2, '0')}` }
  })
})

const tags = nodes.map((i) => i.tag)

const outbounds = [
  {
    type: 'direct',
    tag: 'direct',
  },
  {
    type: 'selector',
    tag: 'select',
    outbounds: ['auto', ...tags],
    interrupt_exist_connections: true,
  },
  {
    type: 'urltest',
    tag: 'auto',
    interval: '3m',
    outbounds: tags,
    interrupt_exist_connections: true,
  },
  ...nodes,
]

const json = JSON.stringify({
  log: {
    level: 'info',
  },
  dns: {
    servers: [
      {
        tag: 'dns-proxy',
        type: 'https',
        server: '1.1.1.1',
        detour: 'select',
      },
      {
        tag: 'dns-direct',
        type: 'quic',
        server: '223.6.6.6',
      },
    ],
    rules: [
      {
        type: 'logical',
        mode: 'or',
        rules: [
          {
            query_type: 'HTTPS',
          },
          {
            rule_set: ['geosite-category-ads-all'],
          },
        ],
        action: 'reject',
      },
      {
        clash_mode: 'Global',
        server: 'dns-proxy',
      },
      {
        clash_mode: 'Direct',
        server: 'dns-direct',
      },
      {
        rule_set: ['geosite-cn'],
        server: 'dns-direct',
      },
      // {
      //   query_type: [
      //     "A",
      //     "AAAA"
      //   ],
      //   server: "dns-fakeip",
      //   rewrite_ttl: 1,
      // },
    ],
    strategy: 'ipv4_only',
    independent_cache: true,
  },
  inbounds: [
    // {
    //   type: "mixed",
    //   tag: "mixed-in",
    //   listen: "127.0.0.1",
    //   listen_port: 10800,
    // },
    {
      type: 'tproxy',
      tag: 'tproxy-in',
      listen: '127.0.0.1',
      listen_port: 12345,
    },
  ],
  outbounds,
  route: {
    default_domain_resolver: {
      server: 'dns-direct',
      strategy: 'ipv4_only',
    },
    final: 'select',
    rules: [
      ...(directIps && directIps.length > 0
        ? [
            {
              ip_cidr: directIps,
              outbound: 'direct',
            },
          ]
        : []),
      {
        action: 'sniff',
      },
      {
        type: 'logical',
        mode: 'or',
        rules: [
          {
            protocol: 'dns',
          },
          {
            port: 53,
          },
        ],
        action: 'hijack-dns',
      },
      {
        ip_is_private: true,
        outbound: 'direct',
      },
      {
        type: 'logical',
        mode: 'or',
        rules: [
          {
            port: 853,
          },
          {
            network: 'udp',
            port: 443,
          },
          // {
          //   protocol: "stun",
          // },
        ],
        action: 'reject',
      },
      {
        clash_mode: 'Global',
        outbound: 'select',
      },
      {
        clash_mode: 'Direct',
        outbound: 'direct',
      },
      {
        action: 'resolve',
        strategy: 'ipv4_only',
      },
      {
        type: 'logical',
        mode: 'or',
        rules: [
          {
            rule_set: ['geosite-cn', 'geoip-cn'],
          },
        ],
        outbound: 'direct',
      },
    ],
    rule_set: [
      {
        type: 'remote',
        tag: 'geoip-cn',
        format: 'binary',
        url: 'https://ghfast.top/https://raw.githubusercontent.com/lyc8503/sing-box-rules/rule-set-geoip/geoip-cn.srs',
        download_detour: 'direct',
      },
      {
        type: 'remote',
        tag: 'geosite-cn',
        format: 'binary',
        url: 'https://ghfast.top/https://raw.githubusercontent.com/lyc8503/sing-box-rules/rule-set-geosite/geosite-cn.srs',
        download_detour: 'direct',
      },
      {
        type: 'remote',
        tag: 'geosite-category-ads-all',
        format: 'binary',
        url: 'https://ghfast.top/https://raw.githubusercontent.com/lyc8503/sing-box-rules/rule-set-geosite/geosite-category-ads-all.srs',
      },
    ],
  },
  experimental: {
    cache_file: {
      enabled: true,
    },
    clash_api: {
      external_controller: '192.168.77.1:9090',
      external_ui: 'ui',
      external_ui_download_url:
        'https://github.com/MetaCubeX/Yacd-meta/archive/gh-pages.zip',
    },
  },
})

await writeFile(outputFile, json)
