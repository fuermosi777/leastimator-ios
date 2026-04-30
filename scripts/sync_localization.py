import re
import os
import collections

# Localization directories
LPROJ_DIRS = {
    "en": "Leastimator/en.lproj/Localizable.strings",
    "zh-Hans": "Leastimator/zh-Hans.lproj/Localizable.strings",
    "de": "Leastimator/de.lproj/Localizable.strings",
    "es-US": "Leastimator/es-US.lproj/Localizable.strings"
}

# SwiftUI patterns to search for in .swift files
PATTERNS = [
    r'Text\(\s*"([^"]+)"\s*\)',
    r'Label\(\s*"([^"]+)"\s*',
    r'Button\(\s*"([^"]+)"\s*',
    r'NavigationLink\(\s*"([^"]+)"\s*',
    r'Picker\(\s*"([^"]+)"\s*',
    r'Toggle\(\s*"([^"]+)"\s*',
    r'Section\(\s*header:\s*Text\(\s*"([^"]+)"\s*\)',
    r'alert\(\s*"([^"]+)"\s*',
    r'\.navigationTitle\(\s*"([^"]+)"\s*\)',
    r'\.navigationBarTitle\(\s*"([^"]+)"\s*'
]

# Manual keys that might not be caught by simple regex
MANUAL_KEYS = [
    "disclaimer",
    "vehicle delete warning message"
]

def normalize_key(s):
    """Normalize SwiftUI interpolation to .strings format."""
    def replacer(match):
        content = match.group(1).lower()
        if any(k in content for k in ['count', 'index', 'threshold', 'value', 'total', 'amount']):
            return '%lld'
        return '%@'
    return re.sub(r'\\\(([^)]+)\)', replacer, s)

def extract_keys_from_codebase(directory):
    keys = set(MANUAL_KEYS)
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.swift'):
                with open(os.path.join(root, file), 'r', encoding='utf-8') as f:
                    content = f.read()
                    for pattern in PATTERNS:
                        matches = re.findall(pattern, content)
                        for m in matches:
                            norm = normalize_key(m)
                            if norm: keys.add(norm)
    return keys

def load_strings(path):
    """Load existing .strings file into a dictionary."""
    if not os.path.exists(path): return {}
    strings = {}
    # Basic .strings parser (handles "key" = "value";)
    pattern = re.compile(r'"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;')
    with open(path, 'r', encoding='utf-8') as f:
        for line in f:
            match = pattern.search(line)
            if match:
                k = match.group(1).replace('\\"', '"')
                v = match.group(2).replace('\\"', '"')
                strings[k] = v
    return strings

def save_strings(path, strings):
    """Save dictionary to .strings file, sorted by key."""
    content = f"/* \n  Localizable.strings\n  Leastimator\n\n  Synced by Antigravity Localization Skill\n*/\n\n"
    for k in sorted(strings.keys()):
        # Escape quotes for .strings format
        key_escaped = k.replace('"', '\\"')
        val_escaped = strings[k].replace('"', '\\"')
        content += f'"{key_escaped}" = "{val_escaped}";\n'
    
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

def sync():
    print("🚀 Starting Localization Sync Skill...")
    
    # 1. Extract keys from code
    code_keys = extract_keys_from_codebase('Leastimator')
    print(f"📦 Extracted {len(code_keys)} keys from codebase.")
    
    for lang, path in LPROJ_DIRS.items():
        print(f"🌐 Processing {lang}...")
        existing = load_strings(path)
        
        # 2. Identify unused keys
        unused = set(existing.keys()) - code_keys
        if unused:
            print(f"  🗑️  Removing {len(unused)} unused keys.")
        
        # 3. Identify missing keys
        missing = code_keys - set(existing.keys())
        if missing:
            print(f"  ✨ Found {len(missing)} missing keys.")
        
        # 4. Build updated dictionary
        updated = {k: existing[k] for k in code_keys if k in existing}
        for k in missing:
            # Default to key itself for English, empty string for others (or use key as placeholder)
            updated[k] = k if lang == 'en' else f"[MISSING: {k}]"
            
        save_strings(path, updated)
        print(f"  ✅ Saved {path}")

if __name__ == "__main__":
    sync()
