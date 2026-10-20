// One-shot server setup — run once, sets everything up, then exits
const {
    Client, GatewayIntentBits, PermissionsBitField,
    ChannelType, EmbedBuilder
} = require("discord.js");
const { token } = require("./config.json");

const client = new Client({
    intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMembers],
});

const CLR = { dark: 0x0a0a0a, accent: 0xcccccc, success: 0x2ecc71 };

function em(title, desc, color) {
    return new EmbedBuilder().setColor(color || CLR.dark).setTitle(title).setDescription(desc).setFooter({ text: "PhantomHub" }).setTimestamp();
}

client.once("ready", async () => {
    console.log(`Bot online as ${client.user.tag}`);
    const guild = client.guilds.cache.first();
    if (!guild) { console.log("No server found!"); process.exit(1); }
    console.log(`Setting up server: ${guild.name} (${guild.id})\n`);

    // ── ROLES ──
    const roleDefs = [
        { name: "⚡ Admin",       color: "#FFFFFF", hoist: true,  perms: [PermissionsBitField.Flags.Administrator] },
        { name: "🔧 Moderator",   color: "#888888", hoist: true,  perms: [PermissionsBitField.Flags.ManageMessages, PermissionsBitField.Flags.KickMembers, PermissionsBitField.Flags.BanMembers, PermissionsBitField.Flags.ManageChannels] },
        { name: "🔑 Code Hunter", color: "#666666", hoist: true,  perms: [] },
        { name: "👻 Member",      color: "#444444", hoist: false, perms: [] },
    ];

    const roles = {};
    for (const r of roleDefs) {
        const existing = guild.roles.cache.find(x => x.name === r.name);
        if (existing) { roles[r.name] = existing; console.log(`  ✓ Role "${r.name}" exists`); continue; }
        try {
            roles[r.name] = await guild.roles.create({ name: r.name, color: r.color, hoist: r.hoist, permissions: r.perms, reason: "PhantomHub setup" });
            console.log(`  ✅ Created role "${r.name}"`);
        } catch (e) { console.log(`  ❌ Role "${r.name}": ${e.message}`); }
    }

    const modRole = roles["🔧 Moderator"];
    const adminRole = roles["⚡ Admin"];

    // ── CATEGORIES & CHANNELS ──
    const structure = [
        { cat: "━━ PHANTOM HUB ━━", channels: [
            { name: "📢・announcements", readOnly: true },
            { name: "📜・rules", readOnly: true },
            { name: "👋・welcome", readOnly: true },
        ]},
        { cat: "━━ SAB CODES ━━", channels: [
            { name: "🔑・active-codes" },
            { name: "🪦・expired-codes", readOnly: true },
            { name: "🤖・bot-commands" },
        ]},
        { cat: "━━ COMMUNITY ━━", channels: [
            { name: "💬・general" },
            { name: "🧠・brainrot-chat" },
            { name: "🎮・sab-discussion" },
            { name: "📸・screenshots" },
            { name: "🔥・flex-your-rots" },
        ]},
        { cat: "━━ SUPPORT ━━", channels: [
            { name: "❓・help" },
            { name: "🐛・bug-reports" },
            { name: "💡・suggestions" },
        ]},
        { cat: "━━ VOICE ━━", channels: [
            { name: "🔊 Lobby", voice: true },
            { name: "🎧 Grinding SAB", voice: true },
            { name: "🔇 AFK", voice: true },
        ]},
        { cat: "━━ STAFF ━━", channels: [
            { name: "📋・staff-chat", staffOnly: true },
            { name: "📊・bot-logs", staffOnly: true },
        ]},
    ];

    const createdChannels = {};

    for (const section of structure) {
        // Create category
        let category = guild.channels.cache.find(c => c.name === section.cat && c.type === ChannelType.GuildCategory);
        if (!category) {
            try {
                category = await guild.channels.create({ name: section.cat, type: ChannelType.GuildCategory, reason: "PhantomHub setup" });
                console.log(`  ✅ Category "${section.cat}"`);
            } catch (e) { console.log(`  ❌ Category "${section.cat}": ${e.message}`); continue; }
        } else { console.log(`  ✓ Category "${section.cat}" exists`); }

        // Create channels
        for (const ch of section.channels) {
            // Check if channel already exists anywhere
            const cleanName = ch.name.replace(/[^\w-]/g, '-').replace(/-+/g, '-').replace(/^-|-$/g, '').toLowerCase();
            const existing = guild.channels.cache.find(c => c.parentId === category.id && (c.name === cleanName || c.name === ch.name));
            if (existing) { createdChannels[ch.name] = existing; console.log(`    ✓ #${ch.name} exists`); continue; }

            const overwrites = [];
            if (ch.readOnly) {
                overwrites.push({ id: guild.id, deny: [PermissionsBitField.Flags.SendMessages], allow: [PermissionsBitField.Flags.ViewChannel] });
            }
            if (ch.staffOnly) {
                overwrites.push({ id: guild.id, deny: [PermissionsBitField.Flags.ViewChannel] });
                if (modRole) overwrites.push({ id: modRole.id, allow: [PermissionsBitField.Flags.ViewChannel, PermissionsBitField.Flags.SendMessages] });
                if (adminRole) overwrites.push({ id: adminRole.id, allow: [PermissionsBitField.Flags.ViewChannel, PermissionsBitField.Flags.SendMessages] });
                // Let bot see it too
                overwrites.push({ id: client.user.id, allow: [PermissionsBitField.Flags.ViewChannel, PermissionsBitField.Flags.SendMessages] });
            }

            try {
                const created = await guild.channels.create({
                    name: ch.name,
                    type: ch.voice ? ChannelType.GuildVoice : ChannelType.GuildText,
                    parent: category.id,
                    permissionOverwrites: overwrites.length ? overwrites : undefined,
                    reason: "PhantomHub setup",
                });
                createdChannels[ch.name] = created;
                console.log(`    ✅ #${ch.name}`);
            } catch (e) { console.log(`    ❌ #${ch.name}: ${e.message}`); }
        }
    }

    // ── WELCOME EMBED ──
    const welcomeCh = Object.values(createdChannels).find(c => c.name.includes("welcome"))
        || guild.channels.cache.find(c => c.name.includes("welcome") && c.type === ChannelType.GuildText);
    if (welcomeCh) {
        try {
            await welcomeCh.send({ embeds: [em("👻 Welcome to PhantomHub", [
                "The home of **PhantomHub** — the SAB exploit toolkit.",
                "",
                "**What we do:**",
                "⚡ Auto code redemption",
                "🧠 AI-powered riddle solver",
                "🔍 Brainrot database & lookup",
                "🎯 And more coming...",
                "",
                "**Quick Start:**",
                "> `/code submit <code>` — Share a code",
                "> `/code list` — See active codes",
                "> `/brainrot info <name>` — Look up any brainrot",
                "> `/phantom help` — All commands",
            ].join("\n"), CLR.accent)] });
            console.log(`\n  ✅ Welcome embed sent`);
        } catch (e) { console.log(`  ❌ Welcome embed: ${e.message}`); }
    }

    // ── RULES EMBED ──
    const rulesCh = Object.values(createdChannels).find(c => c.name.includes("rules"))
        || guild.channels.cache.find(c => c.name.includes("rules") && c.type === ChannelType.GuildText);
    if (rulesCh) {
        try {
            await rulesCh.send({ embeds: [em("📜 Server Rules", [
                "**1.** No spamming or flooding channels",
                "**2.** No fake/troll codes — instant ban",
                "**3.** Keep it chill, no toxicity",
                "**4.** No begging for trades/brainrots",
                "**5.** Use the right channels",
                "**6.** Don't share the script publicly",
                "**7.** Report bugs in bug-reports",
                "**8.** Have fun and flex your rots 🔥",
            ].join("\n"), CLR.dark)] });
            console.log(`  ✅ Rules embed sent`);
        } catch (e) { console.log(`  ❌ Rules embed: ${e.message}`); }
    }

    // ── ANNOUNCEMENTS FIRST POST ──
    const annCh = Object.values(createdChannels).find(c => c.name.includes("announcements"))
        || guild.channels.cache.find(c => c.name.includes("announcements") && c.type === ChannelType.GuildText);
    if (annCh) {
        try {
            await annCh.send({ embeds: [em("🚀 PhantomHub is Live", [
                "The server is officially set up and the bot is running.",
                "",
                "**Current Features:**",
                "• `/code` — Submit, list, expire, search SAB codes",
                "• `/brainrot` — Full brainrot DB with rarity & event lookup",
                "• `/phantom` — Bot stats and help",
                "",
                "More features dropping soon. Stay locked in. 👻",
            ].join("\n"), CLR.success)] });
            console.log(`  ✅ Announcement sent`);
        } catch (e) { console.log(`  ❌ Announcement: ${e.message}`); }
    }

    console.log(`\n══════════════════════════════════════`);
    console.log(`  Server setup complete!`);
    console.log(`══════════════════════════════════════\n`);

    // Done — exit so the main bot can keep running
    process.exit(0);
});

client.login(token);
