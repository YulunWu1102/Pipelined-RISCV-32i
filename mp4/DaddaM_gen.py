from collections import deque
from copy import deepcopy
#2,#3,#4,#6,#9,#13,#19,#28
STAGE1_D = 28
STAGE2_D = 19
STAGE3_D = 13
STAGE4_D = 9
STAGE5_D = 6
STAGE6_D = 4
STAGE7_D = 3
STAGE8_D = 2

def gen_full_adder(A, B, Cin, S, Cout, name):
    ret = "full_adder {} ( .A({}), .B({}), .Cin({}), .S({}), .Cout({}));\n".format(name, A, B, Cin, S, Cout)
    return ret

def gen_half_adder(A, B, S, Cout, name):
    ret = "half_adder {} ( .A({}), .B({}), .S({}), .Cout({}));\n".format(name, A, B, S, Cout)
    return ret

def gen_stage(buffer, stage_d, stage_num):
    prev_adders = 0
    stage = ""
    output_sigs_def = "logic "
    next_stage_buffer = deepcopy(buffer)
    stage_num += 1
    stage += "/* ========================= Stage {} ========================= */\n".format(stage_num)
    for i in range(len(buffer)):
        if len(buffer[i]) + prev_adders <= stage_d:
            continue
        num_fa = (len(buffer[i]) + prev_adders - stage_d) // 2
        num_ha = (len(buffer[i]) + prev_adders - stage_d) % 2
        # print(f"generating {num_fa} full adders and {num_ha} half adders")
        prev_adders = num_fa + num_ha
        # print(i)
        for j in range(num_fa):
            cout = "s{}_{}{}_facout".format(stage_num, i, j)
            s = "s{}_{}{}_fas".format(stage_num, i, j)
            name = "s{}_{}fa{}".format(stage_num, i, j)
            stage += gen_full_adder(next_stage_buffer[i].popleft(), next_stage_buffer[i].popleft(), next_stage_buffer[i].popleft(), s, cout, name)
            next_stage_buffer[i].append(s)
            next_stage_buffer[i+1].append(cout)
            output_sigs_def += "{}, {}, ".format(cout, s)
            
        for j in range(num_ha):
            cout = "s{}_{}{}_hacout".format(stage_num, i, j)
            s = "s{}_{}{}_has".format(stage_num, i, j)
            name = "s{}_{}ha{}".format(stage_num, i, j)
            stage += gen_half_adder(next_stage_buffer[i].popleft(), next_stage_buffer[i].popleft(), s, cout, name)
            next_stage_buffer[i].append(s)
            next_stage_buffer[i+1].append(cout)
            output_sigs_def += "{}, {}, ".format(cout, s)
            
    output_sigs_def = output_sigs_def[:-2] + ";\n"
    stage = output_sigs_def + stage
    return stage, next_stage_buffer

def add_last_stage(stage_8_buf):
    for i in range(len(stage_8_buf)):
        if len(stage_8_buf[i]) != 2:
            if i != 0 and i != 63:
                print(f"Failed sanity check, column {i} contains {len(stage_8_buf[i])} items")
                return ""
    last_stage_str = "logic [63:0] op1, op2, result;\n"
    for i in range(len(stage_8_buf)):
        if len(stage_8_buf[i]) != 0:
            last_stage_str += "assign op1[{}] = {};\n".format(i, stage_8_buf[i].popleft())
        else: 
            last_stage_str += "assign op1[{}] = '{};\n".format(i, 0)
        if len(stage_8_buf[i]) != 0:
            last_stage_str += "assign op2[{}] = {};\n".format(i, stage_8_buf[i].popleft())
        else: 
            last_stage_str += "assign op2[{}] = '{};\n".format(i, 0)
        
    last_stage_str += "assign result = op1 + op2;\n"
    return last_stage_str

stage1_buffer = []
partial_sum_signals = ""
partial_sum_init = "logic "
for i in range(64):
    q = deque()
    start = i if i <= 31 else 31
    end = 0 if i <= 31 else i - 31
    for j in range(start, end-1, -1):
        new_sig = "ps_{}{}".format(i, j)
        partial_sum_init += "{}, ".format(new_sig)
        partial_sum_signals += "assign {} = A[{}] & B[{}]; \n".format(new_sig, j, i-j)
        q.append(new_sig)
    stage1_buffer.append(q)
partial_sum_init = partial_sum_init[:-2] + ";\n"
stage_d_l = [STAGE1_D, STAGE2_D, STAGE3_D, STAGE4_D, STAGE5_D, STAGE6_D, STAGE7_D, STAGE8_D]
prev_buf = stage1_buffer
stage_strs = []
for i, stage in enumerate(stage_d_l):
    stage_str, next_buf = gen_stage(prev_buf, stage, i)
    stage_strs.append(stage_str)
    prev_buf = next_buf
    
last_stage = add_last_stage(next_buf)
fd = open("test.sv", "w")
final_str = partial_sum_init + partial_sum_signals
for str in stage_strs:
    final_str += str
final_str += last_stage
fd.write(final_str)


