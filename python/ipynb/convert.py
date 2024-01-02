import os
import argparse
import json
from base64 import standard_b64encode

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

def save_json(data, filepath): 
    with open(filepath, "w+") as f:
        content = json.dump(data, f)
    return content




def notebook_to_script(filepath, output, output_cell_outputs):
    notebook = load_json(filepath)

    script_content = []
    cell_outputs = {}

    cells = notebook['cells']

    for cell in cells:
        cell_type = cell['cell_type']

        header_elements = [
            f'\n{percent_start}',
            f'[{cell_type}]' if cell_type != 'code' else '',
            'execution_count={0}'.format(cell['execution_count']) if cell_type == 'code' else '' ]
            
        script_content.append(' '.join(header_elements))

        content = ''.join(cell['source'])
        if cell_type == 'code':
            content = f'\n{content}\n'
        elif cell_type == 'markdown':
            content = f'{comment_start} ' + content.replace('\n',f'\n{comment_start} ')
            content = f'\n{content}\n'
        else:
            raise ValueError('Invalid cell type encountered!')

        script_content.append(content)

        if cell_type == 'code':
            cell_outputs[cell['execution_count']] = cell['outputs']

    script_source = ''.join(script_content)

    with open(output, "w+") as f:
        f.write(script_source)

    save_json(cell_outputs, output_cell_outputs)

def image_show_string(image_data):

    def serialize_gr_command(payload, **cmd):
        cmd = ','.join(f'{k}={v}' for k, v in cmd.items())
        ans = []
        w = ans.append
        w(b'\033_G') 
        w(cmd.encode('ascii'))
        if payload:
            w(b';')
            w(payload)
        w(b'\033\\')
        return b''.join(ans)

    def write_chunked(data, **cmd):
        ans = []
        data = standard_b64encode(data)
        while data:
            chunk, data = data[:4096], data[4096:]
            m = 1 if data else 0
            ans.append(serialize_gr_command(payload=chunk, m=m, **cmd))
            cmd.clear()
        return b''.join(ans)

    return write_chunked(image_data, a='T',f=100)


def outputs_to_script(filepath, output):
    all_cell_outputs = load_json(filepath)
    script_content = []
    
    for execution_count in all_cell_outputs.keys():

        # Get the first output only (are more ever present?)
        cell_outputs = all_cell_outputs[execution_count]
        if len(cell_outputs)==0:
            continue

        header_elements = [f'\n{percent_start}', f'execution_count={execution_count}']
        script_content.append(' '.join(header_elements))

        for cell_output in cell_outputs:
            output_type = cell_output['output_type']
            
            if output_type == 'execute_result':
                content = '\n'            
            elif output_type == 'stream':
                content = '\n{0}'.format(''.join(cell_output['text'])) 
            elif output_type == 'display_data':
                image_data = cell_output['data']['image/png']
                content = image_show_string(image_data.encode('utf-8')).decode('utf-8')
                #content = (b'\n\033_Ga=T,f=100,t=f;'+ '~/Documents/RiSchedule/test.png'.encode('utf-8') + b'\033\\').decode('utf-8')
            elif output_type == 'error':
                content = '\n'            
            else:
                raise ValueError('Unknown output type {0}'.format(output_type))

            script_content.append(content)

    script_source = ''.join(script_content)

    with open(output, "w+") as f:
        f.write(script_source)

def script_to_notebook(filepath, outputs_filepath, output):
    return



def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('file', type=str, help='The file to convert')
    parser.add_argument('--output', type=str, help='The output file')
    parser.add_argument('--cell_outputs', type=str, help='The cell outputs file')

    args = parser.parse_args()

    _, extension = os.path.splitext(args.file)

    print(extension)
    if extension=='.ipynb':
        notebook_to_script(args.file, args.output, args.cell_outputs)
    elif extension=='.ipyout':
        outputs_to_script(args.file, args.output)
    else:
        script_to_notebook(args.file, args.cell_outputs, args.output)

if __name__ == '__main__':
    main()
