import os
import re

def replace_in_file(filepath, replacements):
    if not os.path.exists(filepath): return
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content
    for old, new in replacements:
        if callable(old):
            new_content = old(new_content)
        else:
            new_content = new_content.replace(old, new)
            
    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f'Updated {filepath}')

def regex_replace(pattern, repl):
    def replacer(text):
        return re.sub(pattern, repl, text)
    return replacer

dart_files = [os.path.join(r, f) for r, d, fs in os.walk('lib/screens') for f in fs if f.endswith('.dart')]

for f in dart_files:
    replace_in_file(f, [
        ('if (!mounted) return;', 'if (!context.mounted) return;'),
        (regex_replace(r'const\s+([A-Za-z0-9_]+)\s*\(\s*\{\s*Key\?\s+key\s*\}\s*\)\s*:\s*super\s*\(\s*key\s*:\s*key\s*\)\s*;', r'const \1({super.key});'), '')
    ])

replace_in_file('lib/screens/my_leaves_screen.dart', [
    ("import 'package:intl/intl.dart';\n", '')
])

replace_in_file('lib/screens/submit_report_screen.dart', [
    ('List<String> _uploadedFiles', 'final List<String> _uploadedFiles')
])

replace_in_file('lib/screens/unified_employee_screen.dart', [
    ('EdgeInsets.all(16)', 'const EdgeInsets.all(16)'),
    ('value: selectedPriority,', 'initialValue: selectedPriority,'),
    ('value: selectedType,', 'initialValue: selectedType,'),
    ('value: selectedDepartment,', 'initialValue: selectedDepartment,'),
    ('value: selectedStatus,', 'initialValue: selectedStatus,')
])

replace_in_file('lib/screens/unified_admin_screen.dart', [
    ('value: selectedPriority,', 'initialValue: selectedPriority,')
])

replace_in_file('lib/screens/request_leave_screen.dart', [
    ('value: _selectedLeaveType,', 'initialValue: _selectedLeaveType,'),
    ('e.toList(),', 'e,'),
    ('e.toList()', 'e')
])
