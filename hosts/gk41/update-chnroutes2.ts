import { writeFile } from 'node:fs/promises'

const url =
  'https://raw.githubusercontent.com/misakaio/chnroutes2/refs/heads/master/chnroutes.txt'

await writeFile(
  '/tmp/chnroutes2.nft',
  `flush set ip tp cn_v4

add element ip tp cn_v4 {
  ${(await (await fetch(url)).text()).trim().split('\n').join(',\n  ')}
}
`,
)
