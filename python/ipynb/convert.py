import os
import argparse
import json

language_information = {
    'python': { 'extension':'py', 'kernel':'python3' }
}

percent_start = '# %%'
comment_start = '#'

#def generate_cell_ids(num):
#    ids = []
#    len_ = 10
#    alphabet = string.ascii_uppercase + string.ascii_lowercase + string.digits
#
#    ids_flattened = random.choices(alphabet, k=len_ * num)
#    ids = [''.join(ids_flattened[i * len_ : (i + 1) * len_]) for i in range(num)]
#
#    # prevent collision (not really necessary, VERY unlikely)
#    if len(set(ids)) != len(ids):
#        ids = generate_cell_ids(num)
#
#    return ids

def load_json(filepath):
    if os.path.isfile(filepath):
        with open(filepath, "r") as f:
            content = json.load(f)
        return content
    else:
        return {}

def notebook_to_script(filepath, output_filepath):
    notebook = load_json(filepath)

    result = []
    cells = notebook['cells']

    for cell in cells:
        cell_type = cell['cell_type']

        header_elements = [
            f'\n{percent_start}',
            f'[{cell_type}]' if cell_type != 'code' else '',
            'execution_count={0}'.format(cell['execution_count']) if cell_type == 'code' else '' ]
            
        result.append(' '.join(header_elements))

        cell_text = ''.join(cell['source'])
        if cell_type == 'code':
            cell_content = f'\n{cell_text}\n'
        elif cell_type == 'markdown':
            cell_text = f'{comment_start} ' + cell_text.replace('\n',f'\n{comment_start} ')
            cell_content = f'\n{cell_text}\n'
        else:
            raise ValueError('Invalid cell type encountered!')

        result.append(cell_content)

    script_source = ''.join(result)

    with open(output_filepath, "w+") as f:
        f.write(script_source)

def script_to_notebook(filepath, output, outputs_filepath=None):
    return

def convert(filepath, output, outputs_filepath=None):
    _, extension = os.path.splitext(filepath)

    print(extension)
    if extension=='.ipynb':
        notebook_to_script(filepath, output)
    else:
        script_to_notebook(filepath, output, outputs_filepath)
    

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('file', type=str, help='The file convert')
    parser.add_argument('output', type=str, help='The output file')
    args = parser.parse_args()

    convert(args.file, args.output)

if __name__ == '__main__':
    main()
