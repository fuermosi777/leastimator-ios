import re
import os

# Configuration
SOURCE_DIR = 'Leastimator'
LANGUAGES = ['en', 'zh-Hans', 'de', 'es-US']
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
MANUAL_KEYS = ["disclaimer", "vehicle delete warning message"]

def normalize_key(s):
    """Normalize SwiftUI interpolated strings to LocalizedStringKey format."""
    def replacer(match):
        content = match.group(1).lower()
        if any(word in content for word in ['count', 'index', 'threshold', 'value', 'total', 'amount']):
            return '%lld'
        return '%@'
    return re.sub(r'\\\(([^)]+)\)', replacer, s)

def extract_keys_from_code():
    """Scan all Swift files for localizable strings."""
    keys = set()
    for root, _, files in os.walk(SOURCE_DIR):
        for file in files:
            if file.endswith('.swift'):
                with open(os.path.join(root, file), 'r', encoding='utf-8') as f:
                    content = f.read()
                    for pattern in PATTERNS:
                        for match in re.findall(pattern, content):
                            norm = normalize_key(match)
                            if norm: keys.add(norm)
    for key in MANUAL_KEYS:
        keys.add(key)
    return keys

def parse_strings_file(path):
    """Basic parser for "key" = "value"; format."""
    if not os.path.exists(path): return {}
    translations = {}
    with open(path, 'r', encoding='utf-8') as f:
        for line in f:
            # Match "key" = "value"; and handle escaped quotes
            match = re.search(r'^"(.+)"\s*=\s*"(.+)";\s*$', line.strip())
            if match:
                translations[match.group(1).replace('\\"', '"')] = match.group(2).replace('\\"', '"')
    return translations

def save_strings_file(path, translations):
    """Save translations in alphabetical order with header."""
    content = f"/* \n  Localizable.strings\n  Leastimator\n\n  Auto-generated sync file\n*/\n\n"
    for key in sorted(translations.keys()):
        val = translations[key]
        k = key.replace('"', '\\"')
        v = val.replace('"', '\\"')
        content += f'"{k}" = "{v}";\n'
    
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

def sync():
    print("🚀 Starting localization sync...")
    code_keys = extract_keys_from_code()
    print(f"📦 Found {len(code_keys)} unique keys in code.")
    
    for lang in LANGUAGES:
        path = f'{SOURCE_DIR}/{lang}.lproj/Localizable.strings'
        existing = parse_strings_file(path)
        
        new_translations = {}
        missing_count = 0
        unused_count = 0
        
        for key in code_keys:
            if key in existing:
                new_translations[key] = existing[key]
            else:
                new_translations[key] = f"TODO: {key}"
                missing_count += 1
        
        unused_count = len(existing) - (len(code_keys) - missing_count)
        
        save_strings_file(path, new_translations)
        print(f"✅ {lang.upper()}: Updated. ({missing_count} missing, {unused_count} unused removed)")

    print("\n✨ Sync complete! Please check for 'TODO:' entries in .strings files.")

if __name__ == "__main__":
    sync()
