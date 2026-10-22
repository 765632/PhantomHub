// ╔══════════════════════════════════════════════════════════════╗
// ║  PhantomHub Discord Bot + API Server                        ║
// ║  Key System • HWID Lock • Script Protection • Brainrot DB   ║
// ╚══════════════════════════════════════════════════════════════╝

const {
    Client, GatewayIntentBits, REST, Routes,
    EmbedBuilder, ActivityType, PermissionsBitField,
    ActionRowBuilder, ButtonBuilder, ButtonStyle,
    SlashCommandBuilder, ModalBuilder, TextInputBuilder, TextInputStyle
} = require("discord.js");
const express = require("express");
const fs = require("fs");
const path = require("path");
const { findBrainrot, getBrainrotsByEvent, getBrainrotsByRarity } = require("./data/brainrots.js");

// ── Config (env vars for Render, fallback to config.json) ──
let token;
try {
    token = process.env.DISCORD_TOKEN || require("./config.json").token;
} catch {
    token = process.env.DISCORD_TOKEN;
}
const PORT = process.env.PORT || 3000;
const API_SECRET = process.env.API_SECRET || "phantomhub_secret_2024";

// ── Discord Client ──
const client = new Client({
    intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.GuildMessages,
        GatewayIntentBits.MessageContent,
        GatewayIntentBits.GuildMembers,
    ],
});

// ── Theme ──
const CLR = { dark: 0x0a0a0a, accent: 0xcccccc, success: 0x2ecc71, error: 0xe74c3c, warn: 0xf39c12, expired: 0x333333, key: 0x00ff88 };

function embed(title, desc, color) {
    return new EmbedBuilder().setColor(color || CLR.dark).setTitle(title || null).setDescription(desc || null)
        .setFooter({ text: "PhantomHub" }).setTimestamp();
}

// ══════════════════════════════════════════════════
// ── KEY SYSTEM WITH HWID                        ──
// ══════════════════════════════════════════════════

const KEYS_FILE = path.join(__dirname, "data", "keys.json");

function loadKeys() {
    try { if (fs.existsSync(KEYS_FILE)) return JSON.parse(fs.readFileSync(KEYS_FILE, "utf-8")); } catch {}
    return {};
}

function saveKeys(k) {
    try {
        fs.mkdirSync(path.dirname(KEYS_FILE), { recursive: true });
        fs.writeFileSync(KEYS_FILE, JSON.stringify(k, null, 2));
    } catch (e) { console.error("[KEYS] Save failed:", e.message); }
}

function generateKey() {
    const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    const chunk = () => Array.from({ length: 5 }, () => chars[Math.floor(Math.random() * chars.length)]).join("");
    return `PH-${chunk()}-${chunk()}-${chunk()}`;
}

const DURATIONS = {
    "5h":       { label: "5 Hours",   ms: 5 * 3600000 },
    "12h":      { label: "12 Hours",  ms: 12 * 3600000 },
    "24h":      { label: "24 Hours",  ms: 24 * 3600000 },
    "3d":       { label: "3 Days",    ms: 3 * 86400000 },
    "7d":       { label: "7 Days",    ms: 7 * 86400000 },
    "30d":      { label: "30 Days",   ms: 30 * 86400000 },
    "lifetime": { label: "Lifetime",  ms: 0 },
};

let keys = loadKeys();

// Check if key is currently valid
function isKeyValid(key) {
    const data = keys[key];
    if (!data) return false;
    if (!data.redeemedBy) return false;
    if (data.expired) return false;
    if (data.expiresAt !== "never" && Date.now() > data.expiresAt) {
        data.expired = true;
        saveKeys(keys);
        return false;
    }
    return true;
}

// Validate key + HWID combo
function validateKeyHWID(key, hwid) {
    if (!isKeyValid(key)) return { valid: false, reason: "Invalid or expired key" };
    const data = keys[key];

    // First time — lock HWID
    if (!data.hwid) {
        data.hwid = hwid;
        saveKeys(keys);
        return { valid: true, reason: "HWID locked" };
    }

    // HWID matches
    if (data.hwid === hwid) return { valid: true, reason: "OK" };

    // HWID mismatch
    return { valid: false, reason: "HWID mismatch. Use Reset HWID in Discord." };
}

async function cleanExpiredKeys(guild) {
    const verifiedRole = guild.roles.cache.find(r => r.name === "✅ Verified");
    if (!verifiedRole) return;
    const now = Date.now();
    let changed = false;
    for (const [k, data] of Object.entries(keys)) {
        if (!data.redeemedBy || !data.expiresAt) continue;
        if (data.expiresAt === "never") continue;
        if (now > data.expiresAt && !data.expired) {
            data.expired = true;
            changed = true;
            try {
                const member = await guild.members.fetch(data.redeemedBy);
                const hasOther = Object.values(keys).some(kd => kd.redeemedBy === data.redeemedBy && !kd.expired && kd !== data);
                if (!hasOther) await member.roles.remove(verifiedRole);
                console.log(`[KEYS] Expired ${k}`);
            } catch {}
        }
    }
    if (changed) saveKeys(keys);
}

// ══════════════════════════════════════════════════
// ── EXPRESS API SERVER                          ──
// ══════════════════════════════════════════════════

const app = express();
app.use(express.json());

// Health check (Render needs this)
app.get("/", (req, res) => {
    res.json({ status: "online", bot: client.user?.tag || "starting...", keys: Object.keys(keys).length });
});

// Validate key + HWID — called by the Roblox script on launch
app.get("/api/validate", (req, res) => {
    const { key, hwid } = req.query;
    if (!key || !hwid) return res.status(400).json({ valid: false, reason: "Missing key or hwid" });

    const result = validateKeyHWID(key.toUpperCase(), hwid);
    console.log(`[API] Validate: ${key} | HWID: ${hwid.slice(0, 8)}... | ${result.valid ? "✅" : "❌"} ${result.reason}`);
    return res.json(result);
});

// /api/script removed — source code is protected, delivered only through the loader

// Key info endpoint (for script to check expiry etc.)
app.get("/api/keyinfo", (req, res) => {
    const { key } = req.query;
    if (!key) return res.status(400).json({ error: "Missing key" });
    const data = keys[key.toUpperCase()];
    if (!data) return res.status(404).json({ error: "Key not found" });
    res.json({
        valid: isKeyValid(key.toUpperCase()),
        duration: data.label,
        expiresAt: data.expiresAt,
        hwid: data.hwid ? data.hwid.slice(0, 8) + "..." : null,
    });
});

// Serve loader.lua — the one-liner people paste into executors calls this
app.get("/loader.lua", (req, res) => {
    const loaderPath = path.join(__dirname, "loader.lua");
    if (!fs.existsSync(loaderPath)) {
        return res.status(404).send("-- PhantomHub: Loader not found");
    }
    res.type("text/plain").send(fs.readFileSync(loaderPath, "utf-8"));
});

// /load removed — source code is protected, delivered only through the loader

// Start Express
app.listen(PORT, () => {
    console.log(`[API] Server running on port ${PORT}`);
});

// ══════════════════════════════════════════════════
// ── SLASH COMMANDS                              ──
// ══════════════════════════════════════════════════

const slashCommands = [];

const createKeyCmd = new SlashCommandBuilder()
    .setName("create-key").setDescription("Generate a PhantomHub key")
    .setDefaultMemberPermissions(PermissionsBitField.Flags.Administrator)
    .addStringOption(o => o.setName("duration").setDescription("How long the key lasts").setRequired(true)
        .addChoices(
            { name: "5 Hours", value: "5h" }, { name: "12 Hours", value: "12h" },
            { name: "24 Hours", value: "24h" }, { name: "3 Days", value: "3d" },
            { name: "7 Days", value: "7d" }, { name: "30 Days", value: "30d" },
            { name: "Lifetime", value: "lifetime" },
        ))
    .addIntegerOption(o => o.setName("amount").setDescription("How many keys (default 1)").setMinValue(1).setMaxValue(25));
slashCommands.push(createKeyCmd);

slashCommands.push(new SlashCommandBuilder().setName("redeem").setDescription("Redeem a PhantomHub key")
    .addStringOption(o => o.setName("key").setDescription("Your key (PH-XXXXX-XXXXX-XXXXX)").setRequired(true)));

slashCommands.push(new SlashCommandBuilder().setName("key-info").setDescription("Check info about a key")
    .setDefaultMemberPermissions(PermissionsBitField.Flags.Administrator)
    .addStringOption(o => o.setName("key").setDescription("The key to look up").setRequired(true)));

slashCommands.push(new SlashCommandBuilder().setName("key-list").setDescription("List all generated keys")
    .setDefaultMemberPermissions(PermissionsBitField.Flags.Administrator)
    .addStringOption(o => o.setName("filter").setDescription("Filter keys").addChoices(
        { name: "All", value: "all" }, { name: "Unused", value: "unused" },
        { name: "Redeemed", value: "redeemed" }, { name: "Expired", value: "expired" },
    )));

slashCommands.push(new SlashCommandBuilder().setName("revoke-key").setDescription("Revoke a key")
    .setDefaultMemberPermissions(PermissionsBitField.Flags.Administrator)
    .addStringOption(o => o.setName("key").setDescription("Key to revoke").setRequired(true)));

const brainrotCmd = new SlashCommandBuilder().setName("brainrot").setDescription("Brainrot database lookup")
    .addSubcommand(s => s.setName("info").setDescription("Look up a brainrot")
        .addStringOption(o => o.setName("name").setDescription("Brainrot name").setRequired(true)))
    .addSubcommand(s => s.setName("event").setDescription("List brainrots from an event")
        .addStringOption(o => o.setName("event").setDescription("Event name").setRequired(true)
            .addChoices({ name: "Base Game", value: "Base" }, { name: "Halloween", value: "Halloween" },
                { name: "Christmas", value: "Christmas" }, { name: "Valentine", value: "Valentine" }, { name: "Summer", value: "Summer" })))
    .addSubcommand(s => s.setName("rarity").setDescription("List brainrots by rarity")
        .addStringOption(o => o.setName("rarity").setDescription("Rarity tier").setRequired(true)
            .addChoices({ name: "Common", value: "Common" }, { name: "Rare", value: "Rare" },
                { name: "Epic", value: "Epic" }, { name: "Legendary", value: "Legendary" },
                { name: "Mythic", value: "Mythic" }, { name: "Brainrot God", value: "Brainrot God" },
                { name: "Secret", value: "Secret" }, { name: "OG", value: "OG" })));
slashCommands.push(brainrotCmd);

slashCommands.push(new SlashCommandBuilder().setName("phantom").setDescription("PhantomHub bot tools")
    .addSubcommand(s => s.setName("stats").setDescription("Show bot stats"))
    .addSubcommand(s => s.setName("help").setDescription("Show all commands")));

slashCommands.push(new SlashCommandBuilder().setName("ticket-panel").setDescription("Send the ticket panel embed (admin)")
    .setDefaultMemberPermissions(PermissionsBitField.Flags.Administrator));

slashCommands.push(new SlashCommandBuilder().setName("close").setDescription("Close this ticket"));

slashCommands.push(new SlashCommandBuilder().setName("check-purchase").setDescription("Verify if a user bought the PhantomHub gamepass (admin)")
    .setDefaultMemberPermissions(PermissionsBitField.Flags.Administrator)
    .addUserOption(o => o.setName("member").setDescription("Discord member to check").setRequired(true))
    .addStringOption(o => o.setName("roblox_user").setDescription("Their Roblox username").setRequired(true)));

slashCommands.push(new SlashCommandBuilder().setName("ticket-setup").setDescription("Create the ticket category + panel channel (admin)")
    .setDefaultMemberPermissions(PermissionsBitField.Flags.Administrator));

// ══════════════════════════════════════════════════
// ── COMMAND HANDLERS                            ──
// ══════════════════════════════════════════════════

function hasStaffRole(interaction) {
    return interaction.member.roles.cache.some(r => r.name === "+");
}

async function handleCreateKey(interaction) {
    if (interaction.user.id !== interaction.guild.ownerId) return interaction.reply({ embeds: [embed("🔒 No Access", "Only the server owner can generate keys.", CLR.error)], ephemeral: true });
    const duration = interaction.options.getString("duration");
    const amount = interaction.options.getInteger("amount") || 1;
    const durInfo = DURATIONS[duration];
    const generated = [];
    for (let i = 0; i < amount; i++) {
        const key = generateKey();
        keys[key] = { duration, label: durInfo.label, createdAt: Date.now(), createdBy: interaction.user.id,
            redeemedBy: null, redeemedAt: null, expiresAt: null, expired: false, hwid: null };
        generated.push(key);
    }
    saveKeys(keys);
    if (amount === 1) {
        return interaction.reply({ embeds: [embed("🔐 Key Generated", null, CLR.key).addFields(
            { name: "Key", value: `\`\`\`${generated[0]}\`\`\``, inline: false },
            { name: "Duration", value: durInfo.label, inline: true },
            { name: "Status", value: "🟢 Unused", inline: true },
        )], ephemeral: true });
    }
    const keyList = generated.map((k, i) => `**${i + 1}.** \`${k}\``).join("\n");
    return interaction.reply({ embeds: [embed(`🔐 ${amount} Keys Generated`, keyList, CLR.key)
        .addFields({ name: "Duration", value: durInfo.label, inline: true })], ephemeral: true });
}

async function handleRedeem(interaction) {
    const inputKey = interaction.options.getString("key").trim().toUpperCase();
    const data = keys[inputKey];
    if (!data) return interaction.reply({ embeds: [embed("❌ Invalid Key", "That key doesn't exist.", CLR.error)], ephemeral: true });
    if (data.redeemedBy) return interaction.reply({ embeds: [embed("❌ Already Used", "This key has already been redeemed.", CLR.error)], ephemeral: true });
    if (data.expired) return interaction.reply({ embeds: [embed("❌ Expired", "This key has expired.", CLR.expired)], ephemeral: true });

    const durInfo = DURATIONS[data.duration];
    data.redeemedBy = interaction.user.id;
    data.redeemedAt = Date.now();
    data.expiresAt = durInfo.ms === 0 ? "never" : Date.now() + durInfo.ms;
    saveKeys(keys);

    const verifiedRole = interaction.guild.roles.cache.find(r => r.name === "✅ Verified");
    if (verifiedRole) { try { await interaction.member.roles.add(verifiedRole); } catch {} }

    const expiresStr = data.expiresAt === "never" ? "Never (Lifetime)" : `<t:${Math.floor(data.expiresAt / 1000)}:R>`;
    return interaction.reply({ embeds: [embed("✅ Key Redeemed!", `Welcome to PhantomHub, <@${interaction.user.id}>!\n\n**Duration:** ${data.label}\n**Expires:** ${expiresStr}\n\nClick **View Script** to get your script.`, CLR.success)] });
}

async function handleKeyInfo(interaction) {
    if (!hasStaffRole(interaction)) return interaction.reply({ embeds: [embed("🔒 No Access", "You need the **+** role.", CLR.error)], ephemeral: true });
    const inputKey = interaction.options.getString("key").trim().toUpperCase();
    const data = keys[inputKey];
    if (!data) return interaction.reply({ embeds: [embed("❌ Not Found", "Key doesn't exist.", CLR.error)], ephemeral: true });
    let status = "🟢 Unused";
    if (data.expired) status = "🔴 Expired";
    else if (data.redeemedBy) status = "🟡 Redeemed";
    const fields = [
        { name: "Key", value: `\`${inputKey}\``, inline: false },
        { name: "Duration", value: data.label, inline: true },
        { name: "Status", value: status, inline: true },
        { name: "HWID", value: data.hwid ? `\`${data.hwid.slice(0, 12)}...\`` : "Not set", inline: true },
    ];
    if (data.redeemedBy) {
        fields.push({ name: "Redeemed By", value: `<@${data.redeemedBy}>`, inline: true });
        fields.push({ name: "Expires", value: data.expiresAt === "never" ? "Never" : `<t:${Math.floor(data.expiresAt / 1000)}:R>`, inline: true });
    }
    return interaction.reply({ embeds: [embed("🔑 Key Info", null, CLR.accent).addFields(...fields)], ephemeral: true });
}

async function handleKeyList(interaction) {
    if (!hasStaffRole(interaction)) return interaction.reply({ embeds: [embed("🔒 No Access", "You need the **+** role.", CLR.error)], ephemeral: true });
    const filter = interaction.options.getString("filter") || "all";
    let filtered = Object.entries(keys);
    if (filter === "unused") filtered = filtered.filter(([, d]) => !d.redeemedBy && !d.expired);
    if (filter === "redeemed") filtered = filtered.filter(([, d]) => d.redeemedBy && !d.expired);
    if (filter === "expired") filtered = filtered.filter(([, d]) => d.expired);
    if (!filtered.length) return interaction.reply({ embeds: [embed("📭 No Keys", `No ${filter} keys.`, CLR.dark)], ephemeral: true });
    const recent = filtered.slice(-20).reverse();
    const lines = recent.map(([k, d]) => {
        let s = d.expired ? "🔴" : d.redeemedBy ? "🟡" : "🟢";
        return `${s} \`${k}\` — ${d.label}${d.redeemedBy ? ` — <@${d.redeemedBy}>` : ""}`;
    });
    return interaction.reply({ embeds: [embed(`🔑 Keys (${filter})`, lines.join("\n"), CLR.accent)
        .addFields({ name: "Showing", value: `${recent.length}/${filtered.length}`, inline: true },
            { name: "Total", value: `${Object.keys(keys).length}`, inline: true })], ephemeral: true });
}

async function handleRevoke(interaction) {
    if (!hasStaffRole(interaction)) return interaction.reply({ embeds: [embed("🔒 No Access", "You need the **+** role.", CLR.error)], ephemeral: true });
    const inputKey = interaction.options.getString("key").trim().toUpperCase();
    const data = keys[inputKey];
    if (!data) return interaction.reply({ embeds: [embed("❌ Not Found", "Key doesn't exist.", CLR.error)], ephemeral: true });
    data.expired = true;
    saveKeys(keys);
    if (data.redeemedBy) {
        const verifiedRole = interaction.guild.roles.cache.find(r => r.name === "✅ Verified");
        if (verifiedRole) {
            try {
                const member = await interaction.guild.members.fetch(data.redeemedBy);
                const hasOther = Object.values(keys).some(kd => kd.redeemedBy === data.redeemedBy && !kd.expired && kd !== data);
                if (!hasOther) await member.roles.remove(verifiedRole);
            } catch {}
        }
    }
    return interaction.reply({ embeds: [embed("🔴 Revoked", `\`${inputKey}\` revoked.${data.redeemedBy ? ` <@${data.redeemedBy}> access removed.` : ""}`, CLR.error)], ephemeral: true });
}

async function handleBrainrot(interaction) {
    const sub = interaction.options.getSubcommand();
    const re = { "Common": "⬜", "Rare": "🟦", "Epic": "🟪", "Legendary": "🟨", "Mythic": "🟥", "Brainrot God": "💀", "Secret": "⬛", "OG": "🏆" };
    if (sub === "info") {
        const result = findBrainrot(interaction.options.getString("name"));
        if (!result) return interaction.reply({ embeds: [embed("❌", "No brainrot matched.", CLR.error)], ephemeral: true });
        return interaction.reply({ embeds: [embed(`${re[result.rarity] || "❓"} ${result.name}`, null, CLR.accent)
            .addFields({ name: "Rarity", value: result.rarity, inline: true }, { name: "Event", value: result.event, inline: true })] });
    }
    if (sub === "event") {
        const event = interaction.options.getString("event");
        const list = getBrainrotsByEvent(event);
        if (!list.length) return interaction.reply({ embeds: [embed("❌", `No brainrots for **${event}**.`, CLR.error)], ephemeral: true });
        const grouped = {}; list.forEach(b => { (grouped[b.rarity] = grouped[b.rarity] || []).push(b.name); });
        const desc = Object.entries(grouped).map(([r, n]) => `**${r}** (${n.length})\n${n.map(x => `> ${x}`).join("\n")}`).join("\n\n");
        return interaction.reply({ embeds: [embed(`🎪 ${event}`, desc.slice(0, 4000), CLR.accent).addFields({ name: "Total", value: `${list.length}`, inline: true })] });
    }
    if (sub === "rarity") {
        const rarity = interaction.options.getString("rarity");
        const list = getBrainrotsByRarity(rarity);
        if (!list.length) return interaction.reply({ embeds: [embed("❌", `No **${rarity}** brainrots.`, CLR.error)], ephemeral: true });
        return interaction.reply({ embeds: [embed(`${re[rarity] || ""} ${rarity}`, list.map(b => b.name).join(", ").slice(0, 4000), CLR.accent)
            .addFields({ name: "Total", value: `${list.length}`, inline: true })] });
    }
}

async function handlePhantom(interaction) {
    const sub = interaction.options.getSubcommand();
    if (sub === "stats") {
        const total = Object.keys(keys).length;
        const used = Object.values(keys).filter(k => k.redeemedBy).length;
        const active = Object.values(keys).filter(k => k.redeemedBy && !k.expired).length;
        return interaction.reply({ embeds: [embed("📊 PhantomHub Stats", null, CLR.accent).addFields(
            { name: "Total Keys", value: `${total}`, inline: true }, { name: "Used", value: `${used}`, inline: true },
            { name: "Active", value: `${active}`, inline: true }, { name: "Uptime", value: `${Math.floor(process.uptime() / 60)}m`, inline: true },
            { name: "Ping", value: `${client.ws.ping}ms`, inline: true }, { name: "API", value: `Port ${PORT}`, inline: true },
        )] });
    }
    if (sub === "help") {
        const isAdmin = interaction.member.permissions.has(PermissionsBitField.Flags.Administrator);
        const fields = [
            { name: "🔐 Key System", value: "`/redeem <key>` — Redeem a key\nOr use the buttons in #code-sniper" },
            { name: "🧠 Brainrots", value: "`/brainrot info` · `/brainrot event` · `/brainrot rarity`" },
            { name: "🎫 Support", value: "Open a ticket from the #help channel" },
            { name: "⚙️ Bot", value: "`/phantom stats` · `/phantom help`" },
        ];
        if (isAdmin) {
            fields.push({ name: "🔒 Admin", value: "`/create-key` · `/key-info` · `/key-list` · `/revoke-key`\n`/check-purchase` · `/ticket-setup` · `/ticket-panel`" });
        }
        return interaction.reply({ embeds: [embed("👻 PhantomHub Commands", null, CLR.accent).addFields(...fields)] });
    }
}

// ══════════════════════════════════════════════════
// ── PURCHASE VERIFICATION (Roblox Gamepass)     ──
// ══════════════════════════════════════════════════

const GAMEPASS_ID = "2037905491";

async function handleCheckPurchase(interaction) {
    if (!hasStaffRole(interaction)) return interaction.reply({ embeds: [embed("🔒 No Access", "You need the **+** role.", CLR.error)], ephemeral: true });
    const member = interaction.options.getMember("member");
    const robloxUser = interaction.options.getString("roblox_user").trim();

    await interaction.deferReply();

    try {
        // Step 1: Get Roblox user ID from username
        const userResp = await fetch("https://users.roblox.com/v1/usernames/users", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ usernames: [robloxUser], excludeBannedUsers: false })
        });
        const userData = await userResp.json();
        const robloxInfo = userData.data?.[0];

        if (!robloxInfo) {
            return interaction.editReply({ embeds: [embed("❌ User Not Found", `Roblox user **${robloxUser}** doesn't exist.`, CLR.error)] });
        }

        const robloxId = robloxInfo.id;
        const displayName = robloxInfo.displayName || robloxUser;

        // Step 2: Check if they own the gamepass
        const gpResp = await fetch(`https://inventory.roblox.com/v1/users/${robloxId}/items/GamePass/${GAMEPASS_ID}`);
        const gpData = await gpResp.json();

        const owns = gpData.data && gpData.data.length > 0;

        if (owns) {
            // They bought it — verified
            return interaction.editReply({ embeds: [embed("✅ Purchase Verified", [
                `**Discord:** ${member}`,
                `**Roblox:** ${displayName} (\`${robloxUser}\` — ID: ${robloxId})`,
                `**Gamepass:** PHANTOMHUB ✅ Owned`,
                "",
                "Purchase confirmed. You can generate their key with `/create-key`."
            ].join("\n"), CLR.success)] });
        } else {
            // They don't own it — fake purchase
            return interaction.editReply({ embeds: [embed("🚫 Purchase NOT Verified — FAKE", [
                `**Discord:** ${member}`,
                `**Roblox:** ${displayName} (\`${robloxUser}\` — ID: ${robloxId})`,
                `**Gamepass:** PHANTOMHUB ❌ NOT Owned`,
                "",
                "⚠️ This user does **NOT** own the gamepass. They lied about purchasing.",
                "",
                "React with 🔨 to ban them, or handle manually."
            ].join("\n"), CLR.error)] });
        }
    } catch (e) {
        console.error("[CHECK-PURCHASE]", e.message);
        return interaction.editReply({ embeds: [embed("❌ Error", `Couldn't verify: ${e.message}`, CLR.error)] });
    }
}

// ══════════════════════════════════════════════════
// ── TICKET SYSTEM                               ──
// ══════════════════════════════════════════════════

const TICKET_CATEGORY_NAME = "📩 Tickets";
const TICKET_LOG_CHANNEL = "ticket-logs";
const TICKET_PREFIX = "ticket-";

// PhantomHub support knowledge for AI responses
const SUPPORT_KNOWLEDGE = `You are PhantomHub's AI Support Bot. You talk to customers about PhantomHub — what it is, how it works, whether it's safe, troubleshooting, etc. You're chill, friendly, and helpful. Keep responses short (2-4 sentences). Don't be robotic.

WHAT IS PHANTOMHUB:
- PhantomHub is a premium script/hub for the Roblox game "Steal a Brainrot"
- It works with any Roblox script executor that supports loadstring and HttpGet (Potassium, Solara, Wave, Synapse, etc.)
- It gives you a huge advantage in the game with automated features

FEATURES:
- Auto Riddler: Has 3,200+ riddle answers built in. During Admin Abuse events it instantly solves riddles so you get all the rewards. If it doesn't know an answer it falls back to AI (Groq llama-3.3) to figure it out
- Auto Code Redeemer: Automatically redeems all active game codes when you join
- Anti-Lag: Reduces lag by removing unnecessary visual effects in-game
- Clean dark-themed GUI with toggle switches for each feature
- Auto Riddler works for both single and compound riddles (like "name and age" = "SAMMY24")

IS IT SAFE:
- Yes, PhantomHub is safe to use. It runs locally on your PC through your executor
- Your key is HWID-locked meaning nobody else can use it even if they get your key
- The script is loaded from our secure GitHub, verified before execution
- We don't collect any personal data — just your HWID for key verification
- Thousands of users run it daily during Admin Abuse events with no issues
- As with any executor script, use at your own discretion — but PhantomHub itself contains no malware, no rats, no data stealing

HOW TO USE:
1. Get a key from this server (purchase or giveaway)
2. Redeem it with /redeem or the Redeem Key button
3. Open your executor (any that supports loadstring)
4. Join Steal a Brainrot on Roblox
5. Paste this into your executor: script_key="YOUR_KEY"; loadstring(game:HttpGet("https://raw.githubusercontent.com/765632/PhantomHub/master/loader.lua"))()
6. The GUI appears — toggle on what you want

KEY SYSTEM:
- Keys come in: 5h, 12h, 24h, 3 days, 7 days, 30 days, or lifetime
- HWID locks on first use — one key = one device
- If you switch PCs, use the Reset HWID button or ask an admin
- Check your key status with the Key Info button

COMMON ISSUES:
- "Nothing happens when I execute" = Make sure your key is correct, your executor is updated, and HTTP requests are enabled in your executor's settings
- "Access Denied" = Key expired or HWID mismatch. Try resetting HWID
- "Riddler missed a question" = The AI fallback should catch it. If it keeps missing, let us know and we'll add it to the database
- "GUI doesn't show" = Re-execute the script, make sure you're in a Steal a Brainrot server
- "Lag" = Toggle on Anti-Lag in the GUI

BUYING / PRICING:
- We accept two forms of payment: **Robux** (via gamepass) and **Brainrots** (in-game trade)
- For Robux: the buyer purchases this gamepass → https://www.roblox.com/game-pass/2037905491/PHANTOMHUB
- After buying the gamepass, they need to show proof (screenshot) and give their Roblox username so staff can verify
- Staff will run /check-purchase to confirm the gamepass was actually bought
- For Brainrots: the buyer trades brainrots to staff in-game. Which brainrots and how many depends on the key duration — staff will discuss that with the buyer
- Once payment is confirmed, staff generates a key and gives it to them
- Do NOT make up specific prices — just explain the two payment methods (robux gamepass or brainrots) and that staff handles the rest
- If someone says they want to buy, walk them through it: ask if they wanna pay with Robux or Brainrots, then explain the steps
- We occasionally do giveaways and trial keys in announcements
- IMPORTANT: If someone claims they bought the gamepass, tell them to share their Roblox username so staff can verify with /check-purchase. Do NOT just take their word for it

IMPORTANT RULES FOR YOU:
- Never make up information that isn't in this knowledge base
- Never invent pricing, features, or systems that don't exist
- If you don't know something, say "I'm not sure about that — let me grab a staff member to help you out"
- Keep responses chill and friendly, not corporate`;


async function queryTicketAI(userMessage, conversationHistory) {
    const messages = [
        { role: "system", content: SUPPORT_KNOWLEDGE },
        ...conversationHistory.slice(-6),
        { role: "user", content: userMessage }
    ];

    try {
        console.log("[TICKET AI] Calling Groq for:", userMessage.substring(0, 50));
        const resp = await fetch("https://api.groq.com/openai/v1/chat/completions", {
            method: "POST",
            headers: {
                "Authorization": "Bearer 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",
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                model: "openai/gpt-oss-120b",
                messages,
                max_tokens: 300,
                temperature: 0.5,
            })
        });
        const data = await resp.json();
        console.log("[TICKET AI] Response status:", resp.status, "has choices:", !!data.choices);
        if (data.error) console.error("[TICKET AI] API error:", data.error.message || JSON.stringify(data.error));
        return data.choices?.[0]?.message?.content || "An admin will help you shortly.";
    } catch (e) {
        console.error("[TICKET AI] Exception:", e.message);
        return "I'm having trouble connecting right now. An admin will be with you shortly.";
    }
}

// Store ticket conversation history (in memory, resets on restart)
const ticketConversations = {};

async function handleTicketSetup(interaction) {
    const guild = interaction.guild;

    // Create category if it doesn't exist
    let category = guild.channels.cache.find(c => c.name === TICKET_CATEGORY_NAME && c.type === 4);
    if (!category) {
        category = await guild.channels.create({
            name: TICKET_CATEGORY_NAME,
            type: 4, // CategoryChannel
            permissionOverwrites: [
                { id: guild.id, deny: ["ViewChannel"] },
                { id: client.user.id, allow: ["ViewChannel", "SendMessages", "ManageChannels"] },
            ]
        });
    }

    // Create ticket-logs if it doesn't exist
    let logCh = guild.channels.cache.find(c => c.name === TICKET_LOG_CHANNEL);
    if (!logCh) {
        await guild.channels.create({
            name: TICKET_LOG_CHANNEL,
            type: 0,
            parent: category.id,
            permissionOverwrites: [
                { id: guild.id, deny: ["ViewChannel"] },
                { id: client.user.id, allow: ["ViewChannel", "SendMessages"] },
            ]
        });
    }

    return interaction.reply({ embeds: [embed("✅ Ticket System Ready", `Category: **${TICKET_CATEGORY_NAME}**\nLogs: **#${TICKET_LOG_CHANNEL}**\n\nNow run \`/ticket-panel\` in your support channel.`, CLR.success)], ephemeral: true });
}

async function handleTicketPanel(interaction) {
    const panelEmbed = embed("🎫 PhantomHub Support", [
        "Need help? Open a ticket and our AI support bot will assist you instantly.",
        "",
        "**Common topics:**",
        "• Script not loading",
        "• Key issues / HWID reset",
        "• Riddler not answering",
        "• Purchase questions",
        "",
        "Click below to open a ticket 👇",
    ].join("\n"), CLR.dark);

    const row = new ActionRowBuilder().addComponents(
        new ButtonBuilder().setCustomId("open_ticket").setLabel("📩 Open Ticket").setStyle(ButtonStyle.Primary),
    );

    await interaction.channel.send({ embeds: [panelEmbed], components: [row] });
    return interaction.reply({ content: "Panel sent.", ephemeral: true });
}

async function openTicket(interaction, issue) {
    const guild = interaction.guild;
    const user = interaction.user;
    console.log(`[TICKET] ${user.tag} opening ticket...`);

    // Check if user already has an open ticket
    const existing = guild.channels.cache.find(c => c.name.startsWith(TICKET_PREFIX) && c.topic === user.id);
    if (existing) {
        return interaction.reply({ embeds: [embed("❌ Already Open", `You already have a ticket: ${existing}`, CLR.error)], ephemeral: true });
    }

    await interaction.deferReply({ ephemeral: true });

    // Find ticket category
    let category = guild.channels.cache.find(c => c.name === TICKET_CATEGORY_NAME && c.type === 4);
    if (!category) {
        category = await guild.channels.create({ name: TICKET_CATEGORY_NAME, type: 4,
            permissionOverwrites: [{ id: guild.id, deny: ["ViewChannel"] }, { id: client.user.id, allow: ["ViewChannel", "SendMessages", "ManageChannels"] }]
        });
    }

    // Create ticket channel
    const ticketName = `${TICKET_PREFIX}${user.username.toLowerCase().replace(/[^a-z0-9]/g, "").slice(0, 20)}`;
    const channel = await guild.channels.create({
        name: ticketName,
        type: 0,
        parent: category.id,
        topic: user.id,
        permissionOverwrites: [
            { id: guild.id, deny: ["ViewChannel"] },
            { id: user.id, allow: ["ViewChannel", "SendMessages", "ReadMessageHistory"] },
            { id: client.user.id, allow: ["ViewChannel", "SendMessages", "ManageChannels", "ReadMessageHistory"] },
        ]
    });
    console.log(`[TICKET] Created #${ticketName} for ${user.tag}`);

    // Init conversation history
    ticketConversations[channel.id] = [];

    // Check if user has a key
    const userKey = Object.entries(keys).find(([, d]) => d.redeemedBy === user.id && !d.expired);
    const keyInfo = userKey ? `\n**Your Key:** \`${userKey[0]}\`\n**Expires:** ${userKey[1].expiresAt === "never" ? "Never" : `<t:${Math.floor(userKey[1].expiresAt / 1000)}:R>`}` : "\n⚠️ No active key found on your account.";

    const closeRow = new ActionRowBuilder().addComponents(
        new ButtonBuilder().setCustomId("close_ticket").setLabel("🔒 Close Ticket").setStyle(ButtonStyle.Danger),
    );

    const issueBlock = issue ? `\n**Issue:**\n> ${issue.replace(/\n/g, "\n> ")}\n` : "";
    await channel.send({
        embeds: [embed("🎫 Ticket Opened", [
            `Hey ${user}, welcome to PhantomHub support!`,
            "",
            "Our AI bot will answer your questions instantly.",
            "An admin will step in if needed.",
            keyInfo,
            issueBlock,
            "Type below if you need anything else.",
        ].join("\n"), CLR.accent)],
        components: [closeRow]
    });

    return interaction.editReply({ embeds: [embed("✅ Ticket Created", `Your ticket: ${channel}`, CLR.success)] });
}

async function closeTicket(interaction) {
    const channel = interaction.channel;
    if (!channel.name.startsWith(TICKET_PREFIX)) {
        return interaction.reply({ embeds: [embed("❌", "This isn't a ticket channel.", CLR.error)], ephemeral: true });
    }

    // Log the transcript
    const logCh = interaction.guild.channels.cache.find(c => c.name === TICKET_LOG_CHANNEL);
    if (logCh) {
        const msgs = await channel.messages.fetch({ limit: 50 });
        const transcript = msgs.reverse().map(m => `[${m.author.tag}] ${m.content || "(embed/attachment)"}`).join("\n");
        await logCh.send({ embeds: [embed(`📝 Ticket Closed: #${channel.name}`, [
            `**Closed by:** ${interaction.user}`,
            `**Time:** <t:${Math.floor(Date.now() / 1000)}:F>`,
            "",
            "```",
            transcript.slice(0, 3800),
            "```"
        ].join("\n"), CLR.expired)] });
    }

    // Cleanup
    delete ticketConversations[channel.id];

    await interaction.reply({ embeds: [embed("🔒 Closing...", "This ticket will be deleted in 5 seconds.", CLR.error)] });
    setTimeout(() => channel.delete().catch(() => {}), 5000);
}

// ══════════════════════════════════════════════════
// ── TICKET MESSAGE HANDLER (AI Responses)       ──
// ══════════════════════════════════════════════════

client.on("messageCreate", async (message) => {
    // Ignore bots, DMs, non-ticket channels
    if (message.author.bot) return;
    if (!message.guild) return;
    if (!message.channel.name.startsWith(TICKET_PREFIX)) {
        return;
    }
    console.log(`[TICKET MSG] ${message.author.username} in #${message.channel.name}: ${message.content.substring(0, 80)}`);
    if (!message.content || message.content.length < 2) return;

    const channelId = message.channel.id;

    // Init conversation if needed
    if (!ticketConversations[channelId]) ticketConversations[channelId] = [];

    // Add user message to history
    ticketConversations[channelId].push({ role: "user", content: message.content });

    // Show typing
    await message.channel.sendTyping();

    // Get AI response
    const reply = await queryTicketAI(message.content, ticketConversations[channelId]);

    // Add bot response to history
    ticketConversations[channelId].push({ role: "assistant", content: reply });

    // Keep history manageable
    if (ticketConversations[channelId].length > 20) {
        ticketConversations[channelId] = ticketConversations[channelId].slice(-12);
    }

    // Send
    await message.reply({ embeds: [embed(null, reply, CLR.dark)] });
});

// ══════════════════════════════════════════════════
// ── INTERACTION ROUTER                          ──
// ══════════════════════════════════════════════════

client.on("interactionCreate", async (interaction) => {
    try {
        if (interaction.isChatInputCommand()) {
            const n = interaction.commandName;
            if (n === "create-key") return handleCreateKey(interaction);
            if (n === "redeem") return handleRedeem(interaction);
            if (n === "key-info") return handleKeyInfo(interaction);
            if (n === "key-list") return handleKeyList(interaction);
            if (n === "revoke-key") return handleRevoke(interaction);
            if (n === "brainrot") return handleBrainrot(interaction);
            if (n === "phantom") return handlePhantom(interaction);
            if (n === "check-purchase") return handleCheckPurchase(interaction);
            if (n === "ticket-setup") return handleTicketSetup(interaction);
            if (n === "ticket-panel") return handleTicketPanel(interaction);
            if (n === "close") return closeTicket(interaction);
        }

        if (interaction.isButton()) {
            const id = interaction.customId;

            if (id === "view_script") {
                const hasVerified = interaction.member.roles.cache.some(r => r.name === "✅ Verified");
                if (!hasVerified) return interaction.reply({ embeds: [embed("🔒 Access Denied", "You need a valid key.\nClick **Redeem Key** to activate.", CLR.error)], ephemeral: true });

                const userKey = Object.entries(keys).find(([, d]) => d.redeemedBy === interaction.user.id && !d.expired);
                if (!userKey) return interaction.reply({ embeds: [embed("🔒 No Key", "No active key found.", CLR.error)], ephemeral: true });

                const [keyStr, data] = userKey;
                const expiresStr = data.expiresAt === "never" ? "Never (Lifetime)" : `<t:${Math.floor(data.expiresAt / 1000)}:R>`;

                // Per-user loadstring — uses the loader, never exposes raw source
                const userScript = `script_key="${keyStr}"; loadstring(game:HttpGet("https://raw.githubusercontent.com/765632/PhantomHub/master/loader.lua"))()`;

                return interaction.reply({ embeds: [embed("📥 PhantomHub Script", [
                    "Copy and paste into your executor:",
                    "", "```lua", userScript, "```", "",
                    `**Key:** \`${keyStr}\``,
                    `**Expires:** ${expiresStr}`,
                    `**HWID Locked:** ${data.hwid ? "Yes" : "Locks on first use"}`,
                    "", "⚠️ Do not share — your HWID is locked to this key.",
                ].join("\n"), CLR.success)], ephemeral: true });
            }

            if (id === "redeem_key") {
                const modal = new ModalBuilder().setCustomId("redeem_modal").setTitle("Redeem Key");
                modal.addComponents(new ActionRowBuilder().addComponents(
                    new TextInputBuilder().setCustomId("key_input").setLabel("Enter your key")
                        .setPlaceholder("PH-XXXXX-XXXXX-XXXXX").setStyle(TextInputStyle.Short).setRequired(true).setMinLength(5).setMaxLength(50)
                ));
                return interaction.showModal(modal);
            }

            if (id === "key_info") {
                const userKey = Object.entries(keys).find(([, d]) => d.redeemedBy === interaction.user.id && !d.expired);
                if (!userKey) return interaction.reply({ embeds: [embed("🔑 No Active Key", "Click **Redeem Key** to activate.", CLR.warn)], ephemeral: true });
                const [keyStr, data] = userKey;
                const expiresStr = data.expiresAt === "never" ? "Never (Lifetime)" : `<t:${Math.floor(data.expiresAt / 1000)}:R>`;
                return interaction.reply({ embeds: [embed("🔑 Your Key", null, CLR.key).addFields(
                    { name: "Key", value: `\`${keyStr}\``, inline: false },
                    { name: "Duration", value: data.label, inline: true },
                    { name: "Expires", value: expiresStr, inline: true },
                    { name: "HWID", value: data.hwid ? `\`${data.hwid.slice(0, 12)}...\`` : "Not locked yet", inline: true },
                )], ephemeral: true });
            }

            if (id === "get_buyer_role") {
                const hasVerified = interaction.member.roles.cache.some(r => r.name === "✅ Verified");
                if (!hasVerified) return interaction.reply({ embeds: [embed("🔒 No Key", "Redeem a key first.", CLR.error)], ephemeral: true });
                const buyerRole = interaction.guild.roles.cache.find(r => r.name.includes("Buyer"));
                if (buyerRole) {
                    if (interaction.member.roles.cache.has(buyerRole.id)) return interaction.reply({ embeds: [embed("✅ Already Have It", "You already have the Buyer role.", CLR.success)], ephemeral: true });
                    await interaction.member.roles.add(buyerRole);
                    return interaction.reply({ embeds: [embed("✅ Buyer Role Added", "You now have the Buyer role.", CLR.success)], ephemeral: true });
                }
                return interaction.reply({ embeds: [embed("✅ Verified", "You're verified.", CLR.success)], ephemeral: true });
            }

            if (id === "open_ticket") {
                const modal = new ModalBuilder().setCustomId("ticket_issue_modal").setTitle("Open a Ticket");
                const issueInput = new TextInputBuilder().setCustomId("ticket_issue").setLabel("What's your issue?")
                    .setPlaceholder("Describe your problem so we can help faster...")
                    .setStyle(TextInputStyle.Paragraph).setRequired(true).setMinLength(5).setMaxLength(500);
                modal.addComponents(new ActionRowBuilder().addComponents(issueInput));
                return interaction.showModal(modal);
            }
            if (id === "close_ticket") return closeTicket(interaction);

            if (id === "reset_hwid") {
                const hasVerified = interaction.member.roles.cache.some(r => r.name === "✅ Verified");
                if (!hasVerified) return interaction.reply({ embeds: [embed("🔒 No Key", "Need an active key.", CLR.error)], ephemeral: true });
                const userKey = Object.entries(keys).find(([, d]) => d.redeemedBy === interaction.user.id && !d.expired);
                if (!userKey) return interaction.reply({ embeds: [embed("❌ No Key", "No active key found.", CLR.error)], ephemeral: true });
                userKey[1].hwid = null;
                saveKeys(keys);
                return interaction.reply({ embeds: [embed("🔄 HWID Reset", "Your HWID has been cleared. It will lock to your next device on first script launch.", CLR.success)], ephemeral: true });
            }
        }

        if (interaction.isModalSubmit() && interaction.customId === "ticket_issue_modal") {
            const issue = interaction.fields.getTextInputValue("ticket_issue").trim();
            return openTicket(interaction, issue);
        }

        if (interaction.isModalSubmit() && interaction.customId === "redeem_modal") {
            const inputKey = interaction.fields.getTextInputValue("key_input").trim().toUpperCase();
            const data = keys[inputKey];
            if (!data) return interaction.reply({ embeds: [embed("❌ Invalid Key", "Key doesn't exist.", CLR.error)], ephemeral: true });
            if (data.redeemedBy) return interaction.reply({ embeds: [embed("❌ Already Used", "Already redeemed.", CLR.error)], ephemeral: true });
            if (data.expired) return interaction.reply({ embeds: [embed("❌ Expired", "Key expired.", CLR.expired)], ephemeral: true });

            const durInfo = DURATIONS[data.duration];
            data.redeemedBy = interaction.user.id;
            data.redeemedAt = Date.now();
            data.expiresAt = durInfo.ms === 0 ? "never" : Date.now() + durInfo.ms;
            saveKeys(keys);

            const verifiedRole = interaction.guild.roles.cache.find(r => r.name === "✅ Verified");
            if (verifiedRole) { try { await interaction.member.roles.add(verifiedRole); } catch {} }

            const expiresStr = data.expiresAt === "never" ? "Never (Lifetime)" : `<t:${Math.floor(data.expiresAt / 1000)}:R>`;
            return interaction.reply({ embeds: [embed("✅ Key Redeemed!", [
                `Welcome to PhantomHub, <@${interaction.user.id}>!`,
                "", `**Duration:** ${data.label}`, `**Expires:** ${expiresStr}`,
                "", "Click **View Script** to get your script.",
            ].join("\n"), CLR.success)], ephemeral: true });
        }
    } catch (err) {
        console.error("[ERR]", err);
        try {
            const r = { content: "Something broke.", ephemeral: true };
            if (interaction.replied || interaction.deferred) await interaction.followUp(r);
            else await interaction.reply(r);
        } catch {}
    }
});

// ══════════════════════════════════════════════════
// ── AUTO ROLE ON JOIN                           ──
// ══════════════════════════════════════════════════

client.on("guildMemberAdd", async (member) => {
    try {
        const memberRole = member.guild.roles.cache.find(r => r.name === "Member");
        if (memberRole) {
            await member.roles.add(memberRole);
            console.log(`[ROLE] Gave Member role to ${member.user.tag}`);
        }
    } catch (e) {
        console.error("[ROLE]", e.message);
    }
});

// ══════════════════════════════════════════════════
// ── READY                                       ──
// ══════════════════════════════════════════════════

client.once("ready", async () => {
    console.log(`\n╔══════════════════════════════════════╗`);
    console.log(`║  PhantomHub Bot + API Online          ║`);
    console.log(`║  ${client.user.tag.padEnd(37)}║`);
    console.log(`║  Keys: ${String(Object.keys(keys).length).padEnd(31)}║`);
    console.log(`║  API: port ${String(PORT).padEnd(26)}║`);
    console.log(`╚══════════════════════════════════════╝\n`);

    client.user.setActivity("PhantomHub Keys", { type: ActivityType.Watching });

    const rest = new REST({ version: "10" }).setToken(token);
    try {
        console.log(`[BOT] Registering ${slashCommands.length} commands...`);
        await rest.put(Routes.applicationCommands(client.user.id), { body: slashCommands.map(c => c.toJSON()) });
        console.log("[BOT] Commands registered.");
    } catch (err) { console.error("[BOT] Failed:", err.message); }

    setInterval(() => { for (const g of client.guilds.cache.values()) cleanExpiredKeys(g); }, 300000);
});

client.login(token);
