// Cleanup: delete starter channels, remove code channels, rename rots→brainrots, add new features
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
    console.log(`Cleaning up: ${guild.name}\n`);

    // ── DELETE STARTER/DEFAULT CHANNELS ──
    // Discord starter channels are usually "general", "General", "text", "voice" with no category or in default position
    const starterNames = ["general", "text", "voice", "general-voice"];
    for (const ch of guild.channels.cache.values()) {
        // Delete channels that are default Discord starters (no parent / not ours)
        if (starterNames.includes(ch.name) && !ch.parentId) {
            try { await ch.delete("PhantomHub cleanup"); console.log(`  🗑️  Deleted starter #${ch.name}`); } catch (e) { console.log(`  ⚠️  Couldn't delete #${ch.name}: ${e.message}`); }
        }
    }

    // ── DELETE SAB CODES CATEGORY + ITS CHANNELS ──
    const codesCategory = guild.channels.cache.find(c => c.name.includes("SAB CODES") && c.type === ChannelType.GuildCategory);
    if (codesCategory) {
        // Delete all children first
        const children = guild.channels.cache.filter(c => c.parentId === codesCategory.id);
        for (const [, ch] of children) {
            try { await ch.delete("Removing codes section"); console.log(`  🗑️  Deleted #${ch.name}`); } catch (e) { console.log(`  ⚠️  #${ch.name}: ${e.message}`); }
        }
        try { await codesCategory.delete("Removing codes section"); console.log(`  🗑️  Deleted category "SAB CODES"`); } catch (e) { console.log(`  ⚠️  Category: ${e.message}`); }
    }

    // ── RENAME "flex-your-rots" → "flex-your-brainrots" ──
    const rotsChannel = guild.channels.cache.find(c => c.name.includes("flex-your-rots"));
    if (rotsChannel) {
        try { await rotsChannel.setName("🔥・flex-your-brainrots"); console.log(`  ✏️  Renamed flex-your-rots → flex-your-brainrots`); } catch (e) { console.log(`  ⚠️  Rename: ${e.message}`); }
    }

    // Refresh channel cache
    await guild.channels.fetch();

    // ── ADD NEW CHANNELS ──
    // Find existing categories
    const communityCategory = guild.channels.cache.find(c => c.name.includes("COMMUNITY") && c.type === ChannelType.GuildCategory);
    const phantomCategory = guild.channels.cache.find(c => c.name.includes("PHANTOM HUB") && c.type === ChannelType.GuildCategory);
    const staffCategory = guild.channels.cache.find(c => c.name.includes("STAFF") && c.type === ChannelType.GuildCategory);

    const modRole = guild.roles.cache.find(r => r.name.includes("Moderator"));
    const adminRole = guild.roles.cache.find(r => r.name.includes("Admin"));

    // New category: BRAINROT ZONE
    let brainrotCategory = guild.channels.cache.find(c => c.name.includes("BRAINROT") && c.type === ChannelType.GuildCategory);
    if (!brainrotCategory) {
        try {
            brainrotCategory = await guild.channels.create({ name: "━━ BRAINROT ZONE ━━", type: ChannelType.GuildCategory, reason: "PhantomHub update" });
            console.log(`  ✅ Category "BRAINROT ZONE"`);
        } catch (e) { console.log(`  ❌ Category: ${e.message}`); }
    }

    // New category: TRADING
    let tradingCategory = guild.channels.cache.find(c => c.name.includes("TRADING") && c.type === ChannelType.GuildCategory);
    if (!tradingCategory) {
        try {
            tradingCategory = await guild.channels.create({ name: "━━ TRADING ━━", type: ChannelType.GuildCategory, reason: "PhantomHub update" });
            console.log(`  ✅ Category "TRADING"`);
        } catch (e) { console.log(`  ❌ Category: ${e.message}`); }
    }

    // New category: EVENTS
    let eventsCategory = guild.channels.cache.find(c => c.name.includes("EVENTS") && c.type === ChannelType.GuildCategory);
    if (!eventsCategory) {
        try {
            eventsCategory = await guild.channels.create({ name: "━━ EVENTS ━━", type: ChannelType.GuildCategory, reason: "PhantomHub update" });
            console.log(`  ✅ Category "EVENTS"`);
        } catch (e) { console.log(`  ❌ Category: ${e.message}`); }
    }

    // Helper to create channel if not exists
    async function makeChannel(name, parent, opts = {}) {
        const cleanish = name.replace(/[^\w-]/g, '-').replace(/-+/g, '-').replace(/^-|-$/g, '').toLowerCase();
        const existing = guild.channels.cache.find(c => c.parentId === parent?.id && (c.name === cleanish || c.name.includes(cleanish)));
        if (existing) { console.log(`    ✓ #${name} exists`); return existing; }

        const overwrites = [];
        if (opts.readOnly) overwrites.push({ id: guild.id, deny: [PermissionsBitField.Flags.SendMessages], allow: [PermissionsBitField.Flags.ViewChannel] });
        if (opts.staffOnly) {
            overwrites.push({ id: guild.id, deny: [PermissionsBitField.Flags.ViewChannel] });
            if (modRole) overwrites.push({ id: modRole.id, allow: [PermissionsBitField.Flags.ViewChannel, PermissionsBitField.Flags.SendMessages] });
            if (adminRole) overwrites.push({ id: adminRole.id, allow: [PermissionsBitField.Flags.ViewChannel, PermissionsBitField.Flags.SendMessages] });
            overwrites.push({ id: client.user.id, allow: [PermissionsBitField.Flags.ViewChannel, PermissionsBitField.Flags.SendMessages] });
        }
        if (opts.slowmode && !opts.voice) {}

        try {
            const ch = await guild.channels.create({
                name,
                type: opts.voice ? ChannelType.GuildVoice : ChannelType.GuildText,
                parent: parent?.id,
                rateLimitPerUser: opts.slowmode || 0,
                permissionOverwrites: overwrites.length ? overwrites : undefined,
                reason: "PhantomHub update",
            });
            console.log(`    ✅ #${name}`);
            return ch;
        } catch (e) { console.log(`    ❌ #${name}: ${e.message}`); return null; }
    }

    // ── BRAINROT ZONE channels ──
    if (brainrotCategory) {
        await makeChannel("🧬・brainrot-wiki", brainrotCategory, { readOnly: true });
        await makeChannel("📊・rarity-tier-list", brainrotCategory, { readOnly: true });
        await makeChannel("🔍・brainrot-lookup", brainrotCategory);
        await makeChannel("🏆・brainrot-flex", brainrotCategory);
        await makeChannel("💀・brainrot-god-talk", brainrotCategory);
        await makeChannel("🎲・daily-brainrot", brainrotCategory, { readOnly: true });
    }

    // ── TRADING channels ──
    if (tradingCategory) {
        await makeChannel("📢・trading-rules", tradingCategory, { readOnly: true });
        await makeChannel("🔄・trade-requests", tradingCategory, { slowmode: 30 });
        await makeChannel("💎・looking-for", tradingCategory, { slowmode: 30 });
        await makeChannel("✅・successful-trades", tradingCategory);
        await makeChannel("🚫・scammer-reports", tradingCategory);
    }

    // ── EVENTS channels ──
    if (eventsCategory) {
        await makeChannel("📅・event-announcements", eventsCategory, { readOnly: true });
        await makeChannel("🎃・halloween-brainrots", eventsCategory);
        await makeChannel("🎄・christmas-brainrots", eventsCategory);
        await makeChannel("💘・valentine-brainrots", eventsCategory);
        await makeChannel("☀️・summer-brainrots", eventsCategory);
        await makeChannel("🏆・event-leaderboard", eventsCategory, { readOnly: true });
    }

    // ── Add bot-commands to COMMUNITY if not there ──
    if (communityCategory) {
        await makeChannel("🤖・bot-commands", communityCategory);
        await makeChannel("🎵・music-requests", communityCategory);
        await makeChannel("📝・off-topic", communityCategory);
    }

    // ── Add more STAFF channels ──
    if (staffCategory) {
        await makeChannel("🔨・mod-actions", staffCategory, { staffOnly: true });
        await makeChannel("📜・audit-log", staffCategory, { staffOnly: true, readOnly: true });
    }

    // ── SEND EMBEDS TO NEW CHANNELS ──

    // Brainrot wiki embed
    await guild.channels.fetch();
    const wikiCh = guild.channels.cache.find(c => c.name.includes("brainrot-wiki"));
    if (wikiCh) {
        try {
            await wikiCh.send({ embeds: [em("🧬 Brainrot Wiki", [
                "Use `/brainrot info <name>` to look up any brainrot.",
                "",
                "**Rarity Tiers:**",
                "⬜ Common • 🟦 Rare • 🟪 Epic • 🟨 Legendary",
                "🟥 Mythic • 💀 Brainrot God • ⬛ Secret • 🏆 OG",
                "",
                "**Events:**",
                "🎃 Halloween • 🎄 Christmas • 💘 Valentine • ☀️ Summer",
                "",
                "**Notable Brainrots:**",
                "> 💀 Tralalero Tralala — Brainrot God",
                "> 🏆 Skibidi Toilet — OG",
                "> 🏆 Meowl — OG",
                "> ⬛ Griffin — Secret",
                "> ⬛ Cerberus — Secret",
                "> ⬛ Celestial Pegasus — Secret",
                "> ⬛ Polaroidini — Secret",
                "",
                "Use `/brainrot event <name>` or `/brainrot rarity <tier>` for full lists.",
            ].join("\n"), CLR.accent)] });
            console.log(`  ✅ Wiki embed sent`);
        } catch (e) { console.log(`  ⚠️  Wiki embed: ${e.message}`); }
    }

    // Rarity tier list embed
    const tierCh = guild.channels.cache.find(c => c.name.includes("rarity-tier-list"));
    if (tierCh) {
        try {
            await tierCh.send({ embeds: [em("📊 Rarity Tier List", [
                "**⬜ Common** (12 brainrots)",
                "> Noobini Pizzanini, Trippi Troppi, Tim Cheese, Fizzy Soda, Chill Puppy, Spinny Hammy, Swag Soda, W or L, Sigma Boy, Sigma Girl, Noo My Hotspot, Dug Dug Dug",
                "",
                "**🟦 Rare** (11 brainrots)",
                "> Brr Brr Patapim, Cappuccino Assassino, Chimpanzini Bananini, Ballerina Cappuccina, Cocofanto Elefanto, Burrito Bandito, Tung Tung Tung Sahur, La Cucaracha, Money Money Man, John Pork, Smurf Cat",
                "",
                "**🟪 Epic** (21+ brainrots)",
                "> Bombardiro Crocodilo, Gorillo Subwoofero, Rhino Toasterino, Mi Gatito, Quackula, Orcalero Orcala, and more...",
                "",
                "**🟨 Legendary** (25+ brainrots)",
                "> Tralalero Tralala, Dragon Cannelloni, Matteo, Antonio, Alessio, Los Trios, and more...",
                "",
                "**🟥 Mythic** (35+ brainrots)",
                "> Hydra Dragon Cannelloni, Sammyni Spyderini, La Grande Combinasion, Eviledon, and more...",
                "",
                "**💀 Brainrot God** (80+ brainrots)",
                "> Griffin, Cerberus, Celestial Pegasus, Polaroidini, Jackorilla, and more...",
                "",
                "**⬛ Secret** (150+ brainrots)",
                "> 1x1x1x1, Guest 666, Festive 67, and many more...",
                "",
                "**🏆 OG** (3 brainrots)",
                "> Skibidi Toilet, Meowl, Strawberry Elephant",
            ].join("\n"), CLR.accent)] });
            console.log(`  ✅ Tier list embed sent`);
        } catch (e) { console.log(`  ⚠️  Tier list: ${e.message}`); }
    }

    // Trading rules embed
    const tradingRulesCh = guild.channels.cache.find(c => c.name.includes("trading-rules"));
    if (tradingRulesCh) {
        try {
            await tradingRulesCh.send({ embeds: [em("📢 Trading Rules", [
                "**1.** No scamming — instant permaban",
                "**2.** Use the correct format:",
                "> **HAVE:** [brainrot name]",
                "> **WANT:** [brainrot name]",
                "**3.** Both parties must confirm in chat before trading",
                "**4.** Post successful trades in ✅・successful-trades",
                "**5.** Report scammers with proof in 🚫・scammer-reports",
                "**6.** No lowballing or pressuring",
                "**7.** 30 second slowmode is active to prevent spam",
                "**8.** Don't trade with accounts younger than 7 days",
            ].join("\n"), CLR.dark)] });
            console.log(`  ✅ Trading rules embed sent`);
        } catch (e) { console.log(`  ⚠️  Trading rules: ${e.message}`); }
    }

    // Event announcements embed
    const eventAnnCh = guild.channels.cache.find(c => c.name.includes("event-announcements"));
    if (eventAnnCh) {
        try {
            await eventAnnCh.send({ embeds: [em("📅 SAB Events", [
                "This channel tracks all SAB events and their exclusive brainrots.",
                "",
                "**Past Events:**",
                "🎃 **Halloween** — Jacko Spaventosa, Pot Pumpkin, Frankentteo, Zombie Tralala, Mummy Ambalabu...",
                "🎄 **Christmas** — Reindeer Tralala, Santteo, Yeti Claus, Ginger Globo, Ballerina Peppermintina...",
                "💘 **Valentine** — Cupid Hotspot, Luv Luv Luv, Mariachi Corazoni, Serafinna Medusella...",
                "☀️ **Summer** — Dolphini Jetskini, Squalanana, Boba Panda, Astrolero Cervalero...",
                "",
                "Use `/brainrot event <name>` to see the full roster for each event.",
            ].join("\n"), CLR.success)] });
            console.log(`  ✅ Event announcement embed sent`);
        } catch (e) { console.log(`  ⚠️  Event: ${e.message}`); }
    }

    console.log(`\n══════════════════════════════════════`);
    console.log(`  Server update complete!`);
    console.log(`══════════════════════════════════════\n`);
    process.exit(0);
});

client.login(token);
