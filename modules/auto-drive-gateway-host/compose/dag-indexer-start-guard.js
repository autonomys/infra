// Runs before the DAG indexer, on the indexer image's own Node and pg. The
// indexer starts over from its start block in an empty or missing schema, so it
// is refused a database whose progress is behind the last backup's, until the
// database is restored or the deploy is told to start over (see gateway-db.sh).
const fs = require('fs')
const { Client } = require('pg')

const FLOOR_FILE = '/backups/floor/progress-floor'

const floorHeight = () => {
  let text
  try {
    text = fs.readFileSync(FLOOR_FILE, 'utf8')
  } catch (error) {
    if (error.code === 'ENOENT') return null
    throw error
  }
  const match = text.match(/^dag_height=(\d+)$/m)
  return match ? BigInt(match[1]) : null
}

const main = async () => {
  const floor = floorHeight()
  if (floor === null) {
    console.log("start guard: no backup has recorded the DAG index's progress yet")
    return 0
  }

  const client = new Client({
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT),
    database: process.env.DB_DATABASE,
    user: process.env.DB_USER,
    password: process.env.DB_PASS,
    connectionTimeoutMillis: 10000,
    options: '-c default_transaction_read_only=on -c statement_timeout=10s',
  })
  try {
    await client.connect()
  } catch (error) {
    console.error(`start guard: the database is unreachable (${error.code ?? 'no code'})`)
    return 1
  }

  try {
    const present = await client.query(`SELECT to_regclass('"dag-indexer"._metadata') IS NOT NULL AS present`)
    let height = null
    if (present.rows[0].present) {
      const result = await client.query(
        `SELECT value #>> '{}' AS height FROM "dag-indexer"._metadata WHERE key = 'lastProcessedHeight'`,
      )
      if (result.rows.length > 0 && result.rows[0].height !== null) height = BigInt(result.rows[0].height)
    }
    if (height === null || height < floor) {
      console.error(
        `refusing to start: the database's progress (${height ?? 'none'}) is behind the last backup (${floor}); restore it or start empty deliberately`,
      )
      return 1
    }
    console.log(`start guard: progress ${height} is at or above the last backup's ${floor}`)
    return 0
  } finally {
    await client.end()
  }
}

main().then(
  (code) => process.exit(code),
  (error) => {
    console.error(`start guard: ${error.message}`)
    process.exit(1)
  },
)
