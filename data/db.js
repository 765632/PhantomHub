// ── SQLite Database Layer ──
const Database = require("better-sqlite3");
const path = require("path");

const db = new Database(path.join(__dirname, "phantom.db"));

// WAL mode for better concurrent reads
db.pragma("journal_mode = WAL");

// ── Tables ──
db.exec(`
    CREATE TABLE IF NOT EXISTS codes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        submitted_by TEXT NOT NULL,
        submitted_by_id TEXT NOT NULL,
        submitted_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
        expired INTEGER NOT NULL DEFAULT 0,
        uses INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS brainrots (
        name TEXT PRIMARY KEY,
        rarity TEXT,
        event TEXT,
        description TEXT,
        aliases TEXT
    );

    CREATE TABLE IF NOT EXISTS riddles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        category TEXT DEFAULT 'general'
    );

    CREATE TABLE IF NOT EXISTS user_stats (
        user_id TEXT PRIMARY KEY,
        codes_submitted INTEGER DEFAULT 0,
        riddles_solved INTEGER DEFAULT 0,
        brainrot_lookups INTEGER DEFAULT 0
    );
`);

// ── Prepared Statements ──
const stmts = {
    // Codes
    insertCode: db.prepare(`INSERT OR IGNORE INTO codes (code, submitted_by, submitted_by_id) VALUES (?, ?, ?)`),
    getCode: db.prepare(`SELECT * FROM codes WHERE code = ? COLLATE NOCASE`),
    getRecentCodes: db.prepare(`SELECT * FROM codes WHERE expired = 0 ORDER BY submitted_at DESC LIMIT ?`),
    getAllCodes: db.prepare(`SELECT * FROM codes ORDER BY submitted_at DESC LIMIT ?`),
    expireCode: db.prepare(`UPDATE codes SET expired = 1 WHERE code = ? COLLATE NOCASE`),
    bumpUses: db.prepare(`UPDATE codes SET uses = uses + 1 WHERE code = ? COLLATE NOCASE`),
    codeCount: db.prepare(`SELECT COUNT(*) as count FROM codes`),
    activeCodeCount: db.prepare(`SELECT COUNT(*) as count FROM codes WHERE expired = 0`),
    searchCodes: db.prepare(`SELECT * FROM codes WHERE code LIKE ? COLLATE NOCASE ORDER BY submitted_at DESC LIMIT 10`),

    // User Stats
    upsertStat: db.prepare(`
        INSERT INTO user_stats (user_id, codes_submitted, riddles_solved, brainrot_lookups)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(user_id) DO UPDATE SET
            codes_submitted = codes_submitted + excluded.codes_submitted,
            riddles_solved = riddles_solved + excluded.riddles_solved,
            brainrot_lookups = brainrot_lookups + excluded.brainrot_lookups
    `),
    getUserStats: db.prepare(`SELECT * FROM user_stats WHERE user_id = ?`),
    getLeaderboard: db.prepare(`SELECT * FROM user_stats ORDER BY codes_submitted DESC LIMIT ?`),
};

module.exports = { db, stmts };
