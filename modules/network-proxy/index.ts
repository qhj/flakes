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
  values: { 'input-file': inputFile, 'output-file': outputFile },
} = parseArgs({
  args: process.argv.slice(2),
  options: {
    'input-file': {
      type: 'string',
      short: 'i',
    },
    'output-file': {
      type: 'string',
      short: 'o',
    },
  },
})

if (!inputFile || !outputFile) {
  process.exit(1)
}

const input = await readFile(inputFile, { encoding: 'utf8' })

const { upstream, directIpList, directDomainKeywords } = JSON.parse(input) as {
  upstream: string
  directIpList: string[]
  directDomainKeywords: string[]
}

const [prefix] = upstream.split('.json')
if (!prefix) {
  console.error('invalid url')
  process.exit(1)
}

const directDomainSuffixes = ['steamserver.net']

const { hostname } = new URL(upstream)
const resolver = new Resolver()
resolver.setServers(['223.5.5.5'])
const address = await resolver.resolve4(hostname)
const ip = address[0]

if (!ip) {
  console.error('filter query dns record')
  process.exit(1)
}

const { pathname } = new URL(upstream)
const jsonStr = await get(ip, hostname, pathname)

const outboundsByRegion = new Map<string, object[]>()
const config = JSON.parse(jsonStr) as {
  outbounds: { type: string; tag: string }[]
}
const outboundNodes = config.outbounds.filter(
  ({ type }) =>
    type !== 'selector' &&
    type !== 'urltest' &&
    type !== 'block' &&
    type !== 'direct',
)

outboundNodes.forEach((o) => {
  const index = o.tag.lastIndexOf(' ')
  if (index !== -1) {
    const region = o.tag.slice(0, index)
    const regionOutbounds = outboundsByRegion.get(region)
    if (regionOutbounds) {
      regionOutbounds.push(o)
    } else {
      outboundsByRegion.set(region, [o])
    }
  }
})

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
        server: '8.8.8.8',
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
        domain: ['cloudflare-ech.com'],
        server: 'dns-direct',
      },
      {
        domain_suffix: directDomainSuffixes,
        server: 'dns-direct',
      },
      {
        domain_keyword: directDomainKeywords,
        server: 'dns-direct',
      },
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
        clash_mode: 'Direct',
        server: 'dns-direct',
      },
      {
        clash_mode: 'Global',
        server: 'dns-proxy',
      },
      {
        rule_set: ['geosite-cn'],
        server: 'dns-direct',
      },
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
      ...(directIpList && directIpList.length > 0
        ? [
            {
              ip_cidr: directIpList,
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
        domain_suffix: directDomainSuffixes,
        outbound: 'direct',
      },
      {
        domain_keyword: directDomainKeywords,
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
        clash_mode: 'Direct',
        outbound: 'direct',
      },
      {
        clash_mode: 'Global',
        outbound: 'select',
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
        'https://github.com/Zephyruso/zashboard/releases/latest/download/dist.zip',
    },
  },
})

await writeFile(outputFile, json)
