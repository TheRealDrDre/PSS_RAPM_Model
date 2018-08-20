#!/usr/bin/env python

MAIN="""
(load "/projects/actr/actr7/load-act-r.lisp")
(load "/projects/actr/models/PSS_RAPM_Model/rapm-device.lisp")
(load "/projects/actr/models/PSS_RAPM_Model/rapm-model.lisp")
(load "/projects/actr/models/PSS_RAPM_Model/rapm-simulations.lisp")
(general-simulations 200 :fname "simulations-devel4-newchoice-newprobs-newbold-tick-%s-upper-%s-difficulty%s.txt" :tickvals '(%d) :upprbndvals '(%0.1f) :difficulty '(%d))
(quit)
"""

count=16
for tickval in [20, 25, 30, 35]:
    for upper in [1.0, 2.0, 3.0, 4.0]:
        for difficulty in [3, 2, 1]:
            count += 1
            fout = open("test-%02d.lisp" % count, 'w')
            code = MAIN % (tickval, upper, difficulty, tickval, upper, difficulty)
            fout.write(code)
            fout.flush()
            fout.close()
