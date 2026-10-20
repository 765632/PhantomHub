const { Client, GatewayIntentBits, EmbedBuilder, ActionRowBuilder, ButtonBuilder, ButtonStyle } = require("discord.js");
const { token } = require("./config.json");
const client = new Client({ intents: [GatewayIntentBits.Guilds] });

client.once("ready", async () => {
    const guild = client.guilds.cache.first();
    const codeCh = guild.channels.cache.find(c => c.name.includes("code-sniper"));
    if (!codeCh) { console.log("No code-sniper channel!"); process.exit(1); }

    // Main info embed
    const mainEmbed = new EmbedBuilder()
        .setColor(0x0a0a0a)
        .setTitle("👻 PhantomHub — Code Sniper")
        .setDescription([
            "**The ultimate SAB exploit toolkit.**",
            "",
            "⚡ **Auto Code Redeemer** — Snipes codes the second they drop",
            "🧠 **AI Riddle Solver** — Answers riddles instantly with GROQ AI",
            "📡 **Phantom Sniper** — Detects code sections from announcements",
            "🔍 **Brainrot Database** — 1200+ riddle answers built in",
            "🎯 **Auto Submit** — Types and submits codes automatically",
        ].join("\n"))
        .setFooter({ text: "PhantomHub • SAB Code Sniper" })
        .setTimestamp();

    // How to get access embed
    const keyEmbed = new EmbedBuilder()
        .setColor(0x00ff88)
        .setTitle("🔐 How to Get Access")
        .setDescription([
            "**Step 1** — Get a key from the server owner",
            "**Step 2** — Use `/redeem <key>` in any channel",
            "**Step 3** — You'll receive the **✅ Verified** role",
            "**Step 4** — The script will be sent to you",
            "",
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            "",
            "**Key Durations:**",
            "```",
            "5 Hours    │  12 Hours   │  24 Hours",
            "3 Days     │  7 Days     │  30 Days",
            "Lifetime   │             │",
            "```",
            "",
            "Once your key expires, your access is revoked automatically.",
            "Need a key? DM the server owner.",
        ].join("\n"));

    // Features embed
    const featuresEmbed = new EmbedBuilder()
        .setColor(0xcccccc)
        .setTitle("📋 Full Feature List")
        .setDescription([
            "```",
            "┌─────────────────────────────────────┐",
            "│  PHANTOM CODE SNIPER                 │",
            "├─────────────────────────────────────┤",
            "│  • Auto-detects code announcements   │",
            "│  • Accumulates multi-part codes       │",
            "│  • Auto-submits when complete         │",
            "│  • Smart noise filtering              │",
            "│  • Riddle detection & bypass           │",
            "│  • Post-submit cooldown               │",
            "├─────────────────────────────────────┤",
            "│  AI RIDDLE SOLVER                     │",
            "├─────────────────────────────────────┤",
            "│  • 1200+ local answers (SAB_DB)       │",
            "│  • GROQ AI fallback (Llama 3.3 70B)   │",
            "│  • Auto-detects riddle questions       │",
            "│  • Instant answer submission           │",
            "├─────────────────────────────────────┤",
            "│  EXTRAS                               │",
            "├─────────────────────────────────────┤",
            "│  • Clean B&W UI with particles        │",
            "│  • Logs tab for monitoring             │",
            "│  • Toggle controls for all features    │",
            "│  • Potassium executor compatible       │",
            "└─────────────────────────────────────┘",
            "```",
        ].join("\n"));

    const row = new ActionRowBuilder().addComponents(
        new ButtonBuilder()
            .setCustomId("get_script")
            .setLabel("📥 Get Script")
            .setStyle(ButtonStyle.Success),
        new ButtonBuilder()
            .setCustomId("check_key")
            .setLabel("🔑 Check My Key")
            .setStyle(ButtonStyle.Secondary),
    );

    await codeCh.send({ embeds: [mainEmbed, keyEmbed, featuresEmbed], components: [row] });
    console.log("✅ Code Sniper embed sent to #code-sniper");
    process.exit(0);
});

client.login(token);
