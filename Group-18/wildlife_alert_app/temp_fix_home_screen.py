from pathlib import Path

path = Path('c:/Users/Saniyah/wildlife_alert_app/lib/screens/home_screen.dart')
lines = path.read_text('utf-8').splitlines()
lines[143] = "      r\"Could not find the '([^']+)' column|Could not find column \\\"([^\\\"]+)\\\"|Could not find the column '([^']+)'\"," 
del lines[144]
path.write_text('\n'.join(lines) + '\n', 'utf-8')
print('patched', path)
