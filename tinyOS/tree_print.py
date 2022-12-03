
file = open("tree.txt",'r')
lines = file.readlines()
n = len(lines)
count = 0
found = False

matrix = [list() for i in range(n)]
    
for line in lines:
    found = False
    count += 1
    elements = line.strip().split(' ')
    parent = int(elements[1])
    child = int(elements[0])
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
