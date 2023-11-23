"""_summary_
Print the tracker arrays to a file
"""

# Print brick_tracker
with open("brick_tracker.vhd", "w") as f:
    f.write("signal brick_tracker :tracker := (\n")
    for i in range(30):
        for j in range(41):
            if i % 2 == 0: # even rows
                if j == 0:
                    f.write("('1',")
                elif j == 40:
                    f.write("'0'),\n")
                else:
                    f.write("'1',")
            else: # odd rows
                if j == 0:
                    f.write("('1',")
                elif j == 40:
                    f.write("'1'),\n")
                else:
                    f.write("'1',")
    f.write(");\n\n")

# Print brick corner x corridinates
with open("brick_coorids.vhd", "w") as f:
    # print full brick coorids first
    f.write("signal full_brick_x : hhalf_brick_corrid := (")
    for i in range(41):
        if i == 40:
            f.write("-1);\n\n")
        else:
            f.write(f"{((i)*16)+1},")
    
    # print half brick row corrids
    f.write("signal half_brick_x : hhalf_brick_corrid := (")
    coorid = 1
    for i in range(42):
        f.write(f"{coorid},")
        if i == 0:
            coorid+=8
        else:
            coorid+=16
        if i == 41:
            f.write(");\n\n")
    
    # Print brick corner y corridinates
    f.write("signal brick_y : vbrick_corrid := (")
    for i in range(30):
        if i != 29:
            f.write(f"{i*8},")
        else:
            f.write(f"{i*8});\n\n")
            
    
        