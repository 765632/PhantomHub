// ╔══════════════════════════════════════════════════════════╗
// ║  PhantomHub Script Protector                             ║
// ║  Obfuscates phantomhub.luau → data/phantomhub_script.lua ║
// ╚══════════════════════════════════════════════════════════╝
//
// Usage: node protect.js
// Reads: ../phantomhub.luau (or pass path as arg)
// Writes: data/phantomhub_script.lua (obfuscated)

const fs = require("fs");
const path = require("path");

const INPUT = process.argv[2] || path.join(__dirname, "..", "phantomhub.luau");
const OUTPUT = path.join(__dirname, "data", "phantomhub_script.lua");

if (!fs.existsSync(INPUT)) {
    // fallback: check workspace path
    const alt = "C:\\Users\\carmi\\AppData\\Local\\Potassium\\workspace\\phantomhub.luau";
    if (fs.existsSync(alt)) {
        console.log(`[Protector] Using workspace path: ${alt}`);
        protect(alt);
    } else {
        console.error(`[Protector] Source not found: ${INPUT}`);
        process.exit(1);
    }
} else {
    protect(INPUT);
}

function protect(srcPath) {
    const raw = fs.readFileSync(srcPath, "utf-8");
    console.log(`[Protector] Read ${raw.length} chars from ${srcPath}`);

    // ── Step 1: Compress whitespace (keep strings intact) ──
    // We won't strip inside strings, just collapse blank lines and leading spaces
    const lines = raw.split("\n");
    const trimmed = lines
        .filter(l => l.trim() !== "" && !l.trim().startsWith("-- ═"))  // remove decorative comments
        .map(l => {
            // keep inline comments that matter, strip pure decoration
            if (/^\s*--\s*=====/.test(l)) return null;
            return l;
        })
        .filter(Boolean)
        .join("\n");

    // ── Step 2: String table encoding ──
    // Encode the entire script as a byte table, decode + loadstring at runtime
    const bytes = Buffer.from(trimmed, "utf-8");

    // XOR with a rotating key for basic obfuscation
    const xorKey = [0x50, 0x48, 0x41, 0x4E, 0x54, 0x4F, 0x4D]; // "PHANTOM"
    const encoded = [];
    for (let i = 0; i < bytes.length; i++) {
        encoded.push(bytes[i] ^ xorKey[i % xorKey.length]);
    }

    // Split into chunks of 500 to avoid luau string limits
    const CHUNK = 500;
    const chunks = [];
    for (let i = 0; i < encoded.length; i += CHUNK) {
        const slice = encoded.slice(i, i + CHUNK);
        chunks.push(slice.map(b => "\\" + b).join(""));
    }

    // ── Step 3: Build the protected script ──
    const output = `-- PhantomHub Protected | ${new Date().toISOString().split("T")[0]}
-- Do not redistribute.
local _K={${xorKey.join(",")}}
local _C={${chunks.map(c => `"${c}"`).join(",")}}
local _B=""
for i=1,#_C do _B=_B.._C[i] end
local _D={}
for i=1,#_B do
local b=string.byte(_B,i)
_D[#_D+1]=string.char(bit32.bxor(b,_K[((i-1)%#_K)+1]))
end
local _S=table.concat(_D)
local _F,_E=loadstring(_S)
if _F then _F() else warn("[PhantomHub] Protected load failed: "..tostring(_E)) end
`;

    fs.mkdirSync(path.dirname(OUTPUT), { recursive: true });
    fs.writeFileSync(OUTPUT, output, "utf-8");

    const ratio = ((output.length / raw.length) * 100).toFixed(1);
    console.log(`[Protector] ✅ Protected script written to ${OUTPUT}`);
    console.log(`[Protector] Original: ${raw.length} chars → Protected: ${output.length} chars (${ratio}%)`);
    console.log(`[Protector] XOR key: PHANTOM (7-byte rotation)`);
    console.log(`[Protector] ${chunks.length} chunks, ${encoded.length} encoded bytes`);
}
