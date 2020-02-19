
from jinja2 import Template  
import yaml

def good_shit(filenames, configfile):
    
    
    properties = yaml.load(open(configfile))
    print(properties)
        

    for file in filenames:
        with open(file) as f:
            data = f.read()
            t = Template(data)
            print(t.render(properties))
            
            outfile = open("main2.tf", "w")
            outfile.write(t.render(properties))
            outfile.close()
            
            
            
def main():
    good_shit(["test1.jinja"], "config.yaml")            
            
if __name__ == '__main__':
    main()
