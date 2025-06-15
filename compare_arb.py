import json

def compare_arb_files(file1_path, file2_path):
    with open(file1_path, 'r', encoding='utf-8') as f1:
        data1 = json.load(f1)
    with open(file2_path, 'r', encoding='utf-8') as f2:
        data2 = json.load(f2)

    keys1 = set(data1.keys())
    keys2 = set(data2.keys())

    missing_in_file2 = keys1 - keys2
    missing_in_file1 = keys2 - keys1

    if not missing_in_file2 and not missing_in_file1:
        print("Os arquivos têm as mesmas chaves.")
    else:
        if missing_in_file2:
            print(f"Chaves faltando em {file2_path}: {missing_in_file2}")
        if missing_in_file1:
            print(f"Chaves faltando em {file1_path}: {missing_in_file1}")

compare_arb_files('lib/l10n/app_pt.arb', 'lib/l10n/app_en.arb') 