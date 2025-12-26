
import os
import unicodedata

root_dir = '/home/g-kay-g-l-stan/Masaüstü/falla-main-main/assets'

for dirpath, dirnames, filenames in os.walk(root_dir, topdown=False):
    # Rename directories
    for name in dirnames:
        normalized = unicodedata.normalize('NFC', name)
        if name != normalized:
            print(f'Renaming dir: {name} -> {normalized}')
            old_path = os.path.join(dirpath, name)
            new_path = os.path.join(dirpath, normalized)
            try:
                os.rename(old_path, new_path)
            except OSError as e:
                print(f"Error renaming {old_path}: {e}")

    # Rename files
    for name in filenames:
        normalized = unicodedata.normalize('NFC', name)
        if name != normalized:
            print(f'Renaming file: {name} -> {normalized}')
            old_path = os.path.join(dirpath, name)
            new_path = os.path.join(dirpath, normalized)
            try:
                os.rename(old_path, new_path)
            except OSError as e:
                print(f"Error renaming {old_path}: {e}")
