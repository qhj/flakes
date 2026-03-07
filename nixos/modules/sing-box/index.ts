import { parseArgs } from 'node:util'
import { readFile, writeFile } from 'node:fs/promises'
import { Resolver } from 'node:dns/promises'
import https from 'node:https'

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
const directIps = (await readFile(ipsFile, { encoding: 'utf8' }))
	.trim()
	.split(/[\s,]+/)

const { hostname, pathname, search } = new URL(url)
const resolver = new Resolver()
resolver.setServers(['223.5.5.5'])
const address = await resolver.resolve4(hostname)
const ip = address[0]
const { promise, resolve, reject } = Promise.withResolvers<string>()
const req = https.request(
	{
		hostname: ip,
		port: 443,
		path: pathname + search,
		method: 'GET',
		headers: {
			Host: hostname,
		},
	},
	(res) => {
		let data = ''
		res.on('data', (chunk) => (data += chunk))
		res.on('end', () => resolve(data))
	},
)
req.on('error', reject)
req.end()

const base64 = await promise
const nodes: (
	| {
			tag: string
			type: 'vmess'
			server: string
			server_port: number
			uuid: string
			alter_id: number
	  }
	| {
			tag: string
			type: 'ss'
			server: string
			server_port: number
			method: string
			password: string
	  }
)[] = []

atob(base64)
	.split('\n')
	.forEach((s) => {
		const url = new URL(s)
		const type = url.protocol.replace(':', '')
		const config = atob(url.host)
		if (type === 'vmess') {
			const { ps, port, id, aid, add } = JSON.parse(config) as {
				ps: string
				port: string
				id: string
				aid: number
				net: string
				type: string
				tls: string
				add: string
			}
			nodes.push({
				tag: ps,
				type: 'vmess' as const,
				server: add,
				server_port: Number.parseInt(port),
				uuid: id,
				alter_id: aid,
			})
		}
		if (type === 'ss') {
			const arr = config.split(':')
			const arr2 = arr[1]!.split('@')
			nodes.push({
				type: 'shadowsocks' as const,
				tag: url.hash.replace('#', ''),
				server: arr2[1]!,
				server_port: Number.parseInt(arr[2]!),
				method: arr[0]!,
				password: arr2[0]!,
			})
		}
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
			// {
			//   tag: "dns-fakeip",
			//   type: "fakeip",
			//   inet4_range: "198.18.0.0/16",
			// },
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
			  outbound: "direct",
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
