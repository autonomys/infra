#!/usr/bin/env bash
# The gateway database's backups and the progress checks around them. Runs in
# the gateway-db-backup service: nightly from a systemd timer, on each deploy,
# and by hand to restore.
#
# Progress is the DAG index's lastProcessedHeight and the highest block in
# object_mappings. Both only ever rise, so a database behind the progress
# recorded with the last good backup (the floor) has lost data or been
# replaced, and nothing should index it again from scratch by itself.
#
# Usage: gateway-db.sh backup | guard | reset-floor | check-progress | progress
#        | meta <key> | schema-hash | record-schema <sha256> | coverage [from block]
#        | restore <dump name>
set -euo pipefail
# a failed query must stop the script, never read as "no progress"
shopt -s inherit_errexit
umask 077

BACKUPS=/backups
FLOOR_DIR="$BACKUPS/floor"
FLOOR="$FLOOR_DIR/progress-floor"
KEEP=7
KEEP_SUSPECT=2
SCHEMA="dag-indexer"

export PGHOST="$DB_HOST" PGPORT="$DB_PORT" PGDATABASE="$DB_DATABASE" PGUSER="$DB_USER" PGPASSWORD="$DB_PASS"
export PGCONNECT_TIMEOUT=10

die() {
  echo "$*" >&2
  exit 1
}

sql() {
  PGOPTIONS='-c default_transaction_read_only=on -c statement_timeout=60s' psql -X -At -v ON_ERROR_STOP=1 -c "$1"
}

sql_write() {
  PGOPTIONS='-c statement_timeout=60s' psql -X -At -v ON_ERROR_STOP=1 -c "$1"
}

field() {
  sed -n "s/^$1=//p" <<< "$2"
}

# "t|f": whether the DAG index's _metadata and object_mappings exist
tables() {
  sql "SELECT to_regclass('\"$SCHEMA\"._metadata') IS NOT NULL, to_regclass('public.object_mappings') IS NOT NULL"
}

# key=value lines; a height is empty when its index doesn't exist yet
progress() {
  local present counts dag="" mapping="" rows=0
  present="$(tables)"
  if [ "${present%|*}" = t ]; then
    dag="$(sql "SELECT value #>> '{}' FROM \"$SCHEMA\"._metadata WHERE key = 'lastProcessedHeight'")"
  fi
  if [ "${present#*|}" = t ]; then
    counts="$(sql 'SELECT max("blockNumber"), count(*) FROM object_mappings')"
    IFS='|' read -r mapping rows <<< "$counts"
  fi
  printf 'dag_height=%s\nmapping_height=%s\nmapping_rows=%s\n' "$dag" "$mapping" "$rows"
}

# The heights where $1 is behind the floor $2: a height the floor has that $1
# lacks or has lower. A height the floor doesn't have yet can't be behind it.
behind() {
  local key have want out=""
  for key in dag_height mapping_height; do
    want="$(field "$key" "$2")"
    [ -n "$want" ] || continue
    have="$(field "$key" "$1")"
    if [ -z "$have" ] || [ "$have" -lt "$want" ]; then
      out="${out}${key} ${have:-missing} < ${want}; "
    fi
  done
  printf '%s' "${out%; }"
}

read_floor() {
  cat "$FLOOR" 2>/dev/null || true
}

# Replaced whole, so the indexer's read-only mount of the directory never sees
# half a file
write_floor() {
  local tmp
  install -d -m 0755 "$FLOOR_DIR"
  tmp="$(mktemp "$FLOOR_DIR/.progress-floor.XXXXXX")"
  printf 'dag_height=%s\nmapping_height=%s\nfrom=%s\n' "$(field dag_height "$1")" "$(field mapping_height "$1")" "$2" > "$tmp"
  chmod 0644 "$tmp"
  mv "$tmp" "$FLOOR"
}

dumps() {
  find "$BACKUPS" -maxdepth 1 -name 'gateway-*.dump' -printf '%f\n' | sort
}

# $1 what is behind, $2 the floor
refusal() {
  echo "The gateway database's progress is behind the last backup's ($1). Restore the newest dump, $(dumps | tail -1), as the staging README's \"Restoring the gateway database\" describes. To carry on from what the database holds instead, such as an older dump restored on purpose, set database_start_empty = \"$(field from "$2")\" for one apply: it removes this floor, so the indexes resume from that dump, or start over on an empty database." >&2
}

backup() {
  local stamp name before regress
  exec 9> "$BACKUPS/.lock"
  flock -w 900 9 || die "another backup still holds $BACKUPS/.lock"
  rm -f "$BACKUPS"/*.dump.partial
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  name="gateway-$stamp"
  # read before the dump: progress only rises, so the dump holds at least this
  before="$(progress)"
  pg_dump -Fc -f "$BACKUPS/$name.dump.partial"
  mv "$BACKUPS/$name.dump.partial" "$BACKUPS/$name.dump"
  printf 'time=%s\n%s\n' "$stamp" "$before" > "$BACKUPS/$name.progress"
  regress="$(behind "$before" "$(read_floor)")"
  if [ -n "$regress" ]; then
    mv "$BACKUPS/$name.dump" "$BACKUPS/$name.dump.suspect"
    mv "$BACKUPS/$name.progress" "$BACKUPS/$name.progress.suspect"
    find "$BACKUPS" -maxdepth 1 -name 'gateway-*.dump.suspect' -printf '%f\n' | sort | head -n "-$KEEP_SUSPECT" | while read -r old; do
      rm -f "$BACKUPS/$old" "$BACKUPS/${old%.dump.suspect}.progress.suspect"
    done
    die "$name is behind the last backup's progress ($regress), so it is kept as $name.dump.suspect, one of the $KEEP_SUSPECT newest set aside, and doesn't count towards the $KEEP kept"
  fi
  write_floor "$before" "$name"
  dumps | head -n "-$KEEP" | while read -r old; do
    rm -f "$BACKUPS/$old" "$BACKUPS/${old%.dump}.progress"
  done
  echo "$name: $(tr '\n' ' ' <<< "$before")"
}

rewound_floor() {
  local dag
  dag="$(field dag_height "$1")"
  if [ -n "$dag" ] && [ "$ACCEPT_REWIND_TO" -lt "$dag" ]; then
    dag="$ACCEPT_REWIND_TO"
  fi
  printf 'dag_height=%s\nmapping_height=%s\n' "$dag" "$(field mapping_height "$1")"
}

# The deploy's check, before anything changes. The overrides it accepts take
# effect in reset-floor, right before the indexer starts.
guard() {
  local floor now regress
  floor="$(read_floor)"
  if [ -z "$floor" ]; then
    echo "No backup has recorded the gateway database's progress yet"
    return
  fi
  now="$(progress)"
  regress="$(behind "$now" "$floor")"
  if [ -z "$regress" ]; then
    echo "The gateway database is at or above the last backup's progress"
    return
  fi
  if [ -n "${START_EMPTY:-}" ] && [ "$START_EMPTY" = "$(field from "$floor")" ]; then
    echo "The gateway database is behind the last backup ($regress); database_start_empty names this floor, so it goes and the indexes carry on from what the database holds: from a restored older dump, or from the start if it's empty"
    return
  fi
  if [ -n "${ACCEPT_REWIND_TO:-}" ]; then
    regress="$(behind "$now" "$(rewound_floor "$floor")")"
    if [ -z "$regress" ]; then
      echo "The DAG index was rewound to $ACCEPT_REWIND_TO or above, as accept_rewind_to acknowledges"
      return
    fi
  fi
  if [ -n "${START_EMPTY:-}" ]; then
    echo "database_start_empty names $START_EMPTY, and the floor is $(field from "$floor"), so it is left in place." >&2
  fi
  refusal "$regress" "$floor"
  exit 1
}

# Changes the floor only while the database is behind it, and database_start_empty
# only the floor it names, so an override left set does nothing once the
# database has caught up and a later backup has written a new floor
reset_floor() {
  local floor now
  floor="$(read_floor)"
  [ -n "$floor" ] || return 0
  now="$(progress)"
  [ -n "$(behind "$now" "$floor")" ] || return 0
  if [ -n "${START_EMPTY:-}" ] && [ "$START_EMPTY" = "$(field from "$floor")" ]; then
    rm -f "$FLOOR"
    echo "Removed the progress floor $START_EMPTY, as database_start_empty asks: the indexes carry on from what the database holds"
  elif [ -n "${ACCEPT_REWIND_TO:-}" ]; then
    write_floor "$(rewound_floor "$floor")" "rewound-$(date -u +%Y%m%dT%H%M%SZ)"
    echo "Lowered the progress floor's DAG height to $ACCEPT_REWIND_TO, as accept_rewind_to asks"
  fi
}

check_progress() {
  local now regress
  now="$(progress)"
  regress="$(behind "$now" "$(read_floor)")"
  if [ -n "$regress" ]; then
    echo "behind: $regress"
  else
    echo "at or above the floor"
  fi
}

meta() {
  local present
  [[ "$1" =~ ^[A-Za-z]+$ ]] || die "meta takes a _metadata key such as startHeight"
  present="$(tables)"
  if [ "${present%|*}" = t ]; then
    sql "SELECT value #>> '{}' FROM \"$SCHEMA\"._metadata WHERE key = '$1'"
  fi
}

# The sha256 recorded on the schema: "absent" when there is no schema, and
# empty when it has none recorded
schema_hash() {
  local present comment
  present="$(sql "SELECT to_regnamespace('\"$SCHEMA\"') IS NOT NULL")"
  if [ "$present" != t ]; then
    echo absent
    return
  fi
  comment="$(sql "SELECT obj_description(to_regnamespace('\"$SCHEMA\"'), 'pg_namespace')")"
  sed -n 's/^schema.graphql sha256 \([0-9a-f]\{64\}\)$/\1/p' <<< "$comment"
}

# Run before the indexer starts. A missing schema is created here with the hash,
# as the indexer takes an empty schema it finds as it would one it made, so the
# schema never exists without it.
record_schema() {
  local recorded
  [[ "$1" =~ ^[0-9a-f]{64}$ ]] || die "record-schema takes schema.graphql's sha256"
  recorded="$(schema_hash)"
  if [ "$recorded" = absent ]; then
    sql_write "CREATE SCHEMA \"$SCHEMA\"; COMMENT ON SCHEMA \"$SCHEMA\" IS 'schema.graphql sha256 $1'" > /dev/null
    echo "Created the $SCHEMA schema, recording schema.graphql $1"
    return
  fi
  if [ "$recorded" = "$1" ]; then
    return
  fi
  if [ "${ACCEPT_SCHEMA_SHA256:-}" != "$1" ]; then
    die "The $SCHEMA schema records schema.graphql ${recorded:-nothing}, not $1"
  fi
  sql_write "COMMENT ON SCHEMA \"$SCHEMA\" IS 'schema.graphql sha256 $1'" > /dev/null
  echo "Recorded schema.graphql $1 on the $SCHEMA schema"
}

# Indexed nodes from the given block (1 by default) and more than 200 blocks
# below the index's progress with no mapping: mappings arrive at depth 100, so
# each of those has lost its own
coverage() {
  local from="$1" present
  [[ "$from" =~ ^[0-9]+$ ]] || die "coverage takes a block number to count from"
  present="$(tables)"
  if [ "$present" != "t|t" ]; then
    echo "n/a"
    return
  fi
  sql "SELECT count(*) FROM \"$SCHEMA\".nodes n
        WHERE n.block_height >= $from
          AND n.block_height <= (SELECT (value #>> '{}')::bigint - 200 FROM \"$SCHEMA\"._metadata WHERE key = 'lastProcessedHeight')
          AND NOT EXISTS (SELECT 1 FROM object_mappings m WHERE m.hash = n.blake3_hash)"
}

restore() {
  local occupied
  [[ "$1" =~ ^gateway-[0-9]{8}T[0-9]{6}Z\.dump$ ]] || die "restore takes the name of a dump in $BACKUPS, such as $(dumps | tail -1)"
  [ -f "$BACKUPS/$1" ] || die "$BACKUPS/$1 doesn't exist"
  occupied="$(sql "SELECT to_regclass('public.object_mappings') IS NOT NULL OR to_regnamespace('\"$SCHEMA\"') IS NOT NULL")"
  if [ "$occupied" = t ]; then
    die "The $PGDATABASE database already holds object_mappings or the $SCHEMA schema; restore only into an empty database"
  fi
  # one transaction: the start guard and a backup see nothing until it
  # commits, and a failed restore leaves the database empty to retry
  pg_restore --single-transaction --no-owner -d "$PGDATABASE" "$BACKUPS/$1"
  echo "Restored $1. The database now holds:"
  progress
}

case "${1:-}" in
  backup) backup ;;
  guard) guard ;;
  reset-floor) reset_floor ;;
  check-progress) check_progress ;;
  progress) progress ;;
  meta) meta "${2:-}" ;;
  schema-hash) schema_hash ;;
  record-schema) record_schema "${2:-}" ;;
  coverage) coverage "${2:-1}" ;;
  restore) restore "${2:-}" ;;
  *) die "Usage: $0 backup | guard | reset-floor | check-progress | progress | meta <key> | schema-hash | record-schema <sha256> | coverage [from block] | restore <dump name>" ;;
esac
