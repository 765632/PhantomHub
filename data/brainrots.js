// ── Brainrot Knowledge Base (mirrors SAB_DB from PhantomHub) ──

const BRAINROTS = {
    // ═══ COMMON ═══
    "Noobini Pizzanini":    { rarity: "Common", event: "Base" },
    "Trippi Troppi":        { rarity: "Common", event: "Base" },
    "Tim Cheese":           { rarity: "Common", event: "Base" },
    "Fizzy Soda":           { rarity: "Common", event: "Base" },
    "Chill Puppy":          { rarity: "Common", event: "Base" },
    "Spinny Hammy":         { rarity: "Common", event: "Base" },
    "Swag Soda":            { rarity: "Common", event: "Base" },
    "W or L":               { rarity: "Common", event: "Base" },
    "Sigma Boy":            { rarity: "Common", event: "Base" },
    "Sigma Girl":           { rarity: "Common", event: "Base" },
    "Noo My Hotspot":       { rarity: "Common", event: "Base" },
    "Dug Dug Dug":          { rarity: "Common", event: "Base" },

    // ═══ RARE ═══
    "Brr Brr Patapim":            { rarity: "Rare", event: "Base" },
    "Cappuccino Assassino":       { rarity: "Rare", event: "Base" },
    "Chimpanzini Bananini":       { rarity: "Rare", event: "Base" },
    "Ballerina Cappuccina":       { rarity: "Rare", event: "Base" },
    "Cocofanto Elefanto":         { rarity: "Rare", event: "Base" },
    "Burrito Bandito":            { rarity: "Rare", event: "Base" },
    "Tung Tung Tung Sahur":      { rarity: "Rare", event: "Base" },
    "La Cucaracha":               { rarity: "Rare", event: "Base" },
    "Money Money Man":            { rarity: "Rare", event: "Base" },
    "John Pork":                  { rarity: "Rare", event: "Base" },
    "Smurf Cat":                  { rarity: "Rare", event: "Base" },

    // ═══ EPIC ═══
    "Bombardiro Crocodilo":       { rarity: "Epic", event: "Base" },
    "Gorillo Subwoofero":         { rarity: "Epic", event: "Base" },
    "Rhino Toasterino":           { rarity: "Epic", event: "Base" },
    "Rhino Helicopterino":        { rarity: "Epic", event: "Base" },
    "Elefanto Frigo":             { rarity: "Epic", event: "Base" },
    "Quesadilla Crocodila":       { rarity: "Epic", event: "Base" },
    "Spaghetti Tualetti":         { rarity: "Epic", event: "Base" },
    "Nuclearo Dinosauro":         { rarity: "Epic", event: "Base" },
    "Tractoro Dinosauro":         { rarity: "Epic", event: "Base" },
    "Capitano Moby":              { rarity: "Epic", event: "Base" },
    "Donkeyturbo Express":        { rarity: "Epic", event: "Base" },
    "Rang Ring Bus":              { rarity: "Epic", event: "Base" },
    "Quackula":                   { rarity: "Epic", event: "Base" },
    "Mi Gatito":                  { rarity: "Epic", event: "Base" },
    "Perrito Burrito":            { rarity: "Epic", event: "Base" },
    "Chicleteira Bicicleteira":   { rarity: "Epic", event: "Base" },
    "Orcalero Orcala":            { rarity: "Epic", event: "Base" },
    "Blackhole Goat":             { rarity: "Epic", event: "Base" },
    "Karkerkar Kurkur":           { rarity: "Epic", event: "Base" },
    "Pakrahmatmamat":             { rarity: "Epic", event: "Base" },
    "Nacho Spyder":               { rarity: "Epic", event: "Base" },

    // ═══ LEGENDARY ═══
    "Tralalero Tralala":          { rarity: "Legendary", event: "Base" },
    "Dragon Cannelloni":          { rarity: "Legendary", event: "Base" },
    "Matteo":                     { rarity: "Legendary", event: "Base" },
    "Antonio":                    { rarity: "Legendary", event: "Base" },
    "Alessio":                    { rarity: "Legendary", event: "Base" },
    "Los Trios":                  { rarity: "Legendary", event: "Base" },
    "La Vacca Saturno Saturnita": { rarity: "Legendary", event: "Base" },
    "Tralaledon":                 { rarity: "Legendary", event: "Base" },
    "Boba Panda":                 { rarity: "Legendary", event: "Base" },
    "Capi Taco":                  { rarity: "Legendary", event: "Base" },
    "Tipi Topi Taco":             { rarity: "Legendary", event: "Base" },

    // ═══ MYTHIC ═══
    "Hydra Dragon Cannelloni":    { rarity: "Mythic", event: "Base" },
    "Sammyni Spyderini":          { rarity: "Mythic", event: "Base" },
    "Sammyni Fattini":            { rarity: "Mythic", event: "Base" },
    "Chimpanzini Spiderini":      { rarity: "Mythic", event: "Base" },
    "La Grande Combinasion":      { rarity: "Mythic", event: "Base" },
    "La Supreme Combinasion":     { rarity: "Mythic", event: "Base" },
    "La Sahur Combinasion":       { rarity: "Mythic", event: "Base" },
    "Eviledon":                   { rarity: "Mythic", event: "Base" },

    // ═══ BRAINROT GOD ═══
    "Griffin":                    { rarity: "Brainrot God", event: "Base" },
    "Cerberus":                   { rarity: "Brainrot God", event: "Base" },
    "Celestial Pegasus":          { rarity: "Brainrot God", event: "Base" },
    "Polaroidini":                { rarity: "Brainrot God", event: "Base" },

    // ═══ SECRET ═══
    "1x1x1x1":                   { rarity: "Secret", event: "Base" },
    "Guest 666":                  { rarity: "Secret", event: "Base" },

    // ═══ OG ═══
    "Skibidi Toilet":             { rarity: "OG", event: "Base" },
    "Meowl":                      { rarity: "OG", event: "Base" },
    "Strawberry Elephant":        { rarity: "OG", event: "Base" },

    // ═══ HALLOWEEN EVENT ═══
    "Jacko Spaventosa":           { rarity: "Legendary", event: "Halloween" },
    "Pot Pumpkin":                { rarity: "Epic", event: "Halloween" },
    "Pumpkin Spyderini":          { rarity: "Mythic", event: "Halloween" },
    "Jackorilla":                 { rarity: "Brainrot God", event: "Halloween" },
    "Frankentteo":                { rarity: "Legendary", event: "Halloween" },
    "Zombie Tralala":             { rarity: "Epic", event: "Halloween" },
    "Trickolino":                 { rarity: "Rare", event: "Halloween" },
    "Mummy Ambalabu":             { rarity: "Epic", event: "Halloween" },
    "Vulturino Skeletono":        { rarity: "Rare", event: "Halloween" },
    "La Spooky Grande":           { rarity: "Mythic", event: "Halloween" },
    "Spooky and Pumpky":          { rarity: "Common", event: "Halloween" },
    "La Casa Boo":                { rarity: "Epic", event: "Halloween" },
    "Coffin Tung Tung Tung Sahur":{ rarity: "Rare", event: "Halloween" },

    // ═══ CHRISTMAS EVENT ═══
    "Reindeer Tralala":           { rarity: "Epic", event: "Christmas" },
    "Santteo":                    { rarity: "Legendary", event: "Christmas" },
    "Santa Hotspot":              { rarity: "Common", event: "Christmas" },
    "Giftini Spyderini":          { rarity: "Rare", event: "Christmas" },
    "Yeti Claus":                 { rarity: "Mythic", event: "Christmas" },
    "Ho Ho Ho Sahur":             { rarity: "Rare", event: "Christmas" },
    "Jingle Jingle Sahur":        { rarity: "Rare", event: "Christmas" },
    "Ginger Globo":               { rarity: "Epic", event: "Christmas" },
    "Money Money Reindeer":       { rarity: "Common", event: "Christmas" },
    "Reinito Sleighito":          { rarity: "Rare", event: "Christmas" },
    "Frio Ninja":                 { rarity: "Epic", event: "Christmas" },
    "Ballerina Peppermintina":    { rarity: "Legendary", event: "Christmas" },
    "La Jolly Grande":            { rarity: "Mythic", event: "Christmas" },
    "Festive 67":                 { rarity: "Secret", event: "Christmas" },

    // ═══ VALENTINE EVENT ═══
    "Cupid Hotspot":              { rarity: "Common", event: "Valentine" },
    "Luv Luv Luv":                { rarity: "Epic", event: "Valentine" },
    "Cupid Cupid Sahur":          { rarity: "Rare", event: "Valentine" },
    "Love Love Love Sahur":       { rarity: "Rare", event: "Valentine" },
    "Love Love Bear":             { rarity: "Epic", event: "Valentine" },
    "Lovin Rose":                 { rarity: "Common", event: "Valentine" },
    "La Romantic Grande":         { rarity: "Mythic", event: "Valentine" },
    "Noo My Heart":               { rarity: "Common", event: "Valentine" },
    "Mariachi Corazoni":          { rarity: "Legendary", event: "Valentine" },
    "Rosey and Teddy":            { rarity: "Epic", event: "Valentine" },
    "Serafinna Medusella":        { rarity: "Brainrot God", event: "Valentine" },

    // ═══ SUMMER EVENT ═══
    "Dolphini Jetskini":          { rarity: "Epic", event: "Summer" },
    "Squalanana":                 { rarity: "Rare", event: "Summer" },
    "Astrolero Cervalero":        { rarity: "Legendary", event: "Summer" },
};

// Build a lowercase lookup map
const LOOKUP = {};
for (const [name, data] of Object.entries(BRAINROTS)) {
    LOOKUP[name.toLowerCase()] = { name, ...data };
}

function findBrainrot(query) {
    const q = query.toLowerCase().trim();
    // exact match
    if (LOOKUP[q]) return LOOKUP[q];
    // partial match
    const partial = Object.entries(LOOKUP).find(([k]) => k.includes(q));
    if (partial) return partial[1];
    // fuzzy — find closest
    let best = null, bestScore = 0;
    for (const [k, v] of Object.entries(LOOKUP)) {
        let score = 0;
        const words = q.split(/\s+/);
        for (const w of words) {
            if (k.includes(w)) score += w.length;
        }
        if (score > bestScore) { bestScore = score; best = v; }
    }
    return bestScore >= 3 ? best : null;
}

function getBrainrotsByEvent(event) {
    return Object.entries(BRAINROTS)
        .filter(([, d]) => d.event.toLowerCase() === event.toLowerCase())
        .map(([name, data]) => ({ name, ...data }));
}

function getBrainrotsByRarity(rarity) {
    return Object.entries(BRAINROTS)
        .filter(([, d]) => d.rarity.toLowerCase() === rarity.toLowerCase())
        .map(([name, data]) => ({ name, ...data }));
}

function getAllEvents() {
    const events = new Set();
    for (const d of Object.values(BRAINROTS)) events.add(d.event);
    return [...events];
}

function getAllRarities() {
    const rarities = new Set();
    for (const d of Object.values(BRAINROTS)) rarities.add(d.rarity);
    return [...rarities];
}

module.exports = { BRAINROTS, LOOKUP, findBrainrot, getBrainrotsByEvent, getBrainrotsByRarity, getAllEvents, getAllRarities };
