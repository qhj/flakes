import { writeFile } from 'node:fs/promises'

const files = [
  'accelerated-domains.china.conf',
  'apple.china.conf',
  'bogus-nxdomain.china.conf',
  'google.china.conf',
]
const prefix =
  'https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/refs/heads/master/'

await Promise.all(
  files.map(async (f) =>
    writeFile(
      `/etc/dnsmasq.d/${f}`,
      (await (await fetch(prefix + f)).text()).replaceAll(
        '114.114.114.114',
        '223.5.5.5',
      ),
    ),
  ),
)
