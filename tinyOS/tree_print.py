import re

file = open("tree.txt",'r')
lines = file.readlines()
n = len(lines)
count = 0
found = False

matrix = [list() for i in range(n)]
all_nodes = list()
max_node = 0
    
for line in lines:
    found = False
    count += 1
    elements = re.sub('[: |]', '', line)
    elements = elements.split(')')
    elements = elements[1].split('=>')    
    parent = int(elements[1])
    child = int(elements[0])
    if child>max_node:
        max_node=child
    if parent>max_node:
        max_node=parent
    all_nodes.append(child)
    all_nodes.append(parent)
    for m in matrix:
        if (len(m) != 0) and (m[0] == parent):
            m.append(child)
            found = True
    if found == False:
        for m in matrix:
            if len(m) == 0:
                m.append(parent)
                m.append(child)
                break
            
for m in matrix:
    if len(m)!=0:
        print
        print("-----------------------")
        print("Parent:       " + str(m[0]))
        print("              |")
        print("              V")
        print("Children: "),
        for i in range(1,len(m)-1):
            print(str(m[i])+", "),
        print(str(m[len(m)-1])),

print
print("Max node is: "+str(max_node))
for i in range(0,max_node):
    found = False
    for j in range(0,len(all_nodes)):
        if all_nodes[j] == i:
            found = True
    if not found:
        print("Node "+str(i)+"not found!")
