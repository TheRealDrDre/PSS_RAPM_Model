import random
import math
import matplotlib.pyplot as plt
import matplotlib.colors as colors
import matplotlib.cm as cmx
import numpy as np

class Feature():
    """A class with feature and D1/D2 selectors"""
    def __init__(self, alpha = 0.2, d1 = 1, d2 = 1, temperature = 0.1, anticorrelated = True, lowbounded = True):
        self._selected = None
        self.lowbounded = lowbounded
        self.alpha = alpha
        self.d1 = d1
        self.d2 = d2
        self.temperature = temperature
        self.anticorrelated = anticorrelated
        self.go = random.uniform(-0.1, 0.1)
        self.nogo = random.uniform(-0.1, 0.1)
        self.select()
    
    def select(self):
        """Selects whether to keep or discard a feature"""
        t = self.temperature
        Q = [self.go, self.nogo]
        X = [math.exp(x / t) for x in Q]
        d = sum(X)
        P = [x / d for x in X]
        C = [sum(P[0:(i + 1)]) for i in range(len(P))]
        r = random.random()
        if r <= C[0]:
            self.selected = True
        else:
            self.selected = False
    
    def __repr__(self):
        return "<%.2f / %.2f [%s]>" % (self.go, self.nogo, self.selected)
    
    def __str__(self):
        return self.__repr__()
    
    def update(self, rt):
        """Rt is the reward"""
        a = self.alpha
        d1 = self.d1
        d2 = self.d2
        
        if self.selected:
            oldq = self.go
            newq = oldq + a * ((rt * d1) - oldq)
            self.go = newq
            
            if self.anticorrelated:
                oldq = self.nogo
                newq = oldq + a * ((rt * d2 * -1) - oldq)
                self.nogo = newq
        else:
            oldq = self.nogo
            newq = oldq + a * ((rt * d2) - oldq)
            self.nogo = newq
            
            if self.anticorrelated:
                oldq = self.go
                newq = oldq + a * ((rt * d1 * -1) - oldq)
                self.go = newq
                
    @property
    def selected(self):
        return self._selected
    
    @selected.setter
    def selected(self, val):
        self._selected = val
        
    @property
    def go(self):
        return self._go
    
    @go.setter
    def go(self, val):
        if self.lowbounded:
            val = max(val, 0)
        self._go = val

    @property
    def nogo(self):
        return self._nogo
    
    @nogo.setter
    def nogo(self, val):
        if self.lowbounded:
            val = max(val, 0)
        self._nogo = val
        
    @property
    def selected_binary(self):
        if self.selected:
            return 1
        else:
            return 0
        
class FeatureSelector():
    """A class that attempts to solve a categorization problem"""
    def __init__ (self, nfeatures, ncorrect = 1, maxruns = 100, temperature = 0.1, alpha = 0.2, d1 = 1,
                 d2 = 1, anticorrelated = True):
        self.nfeatures = nfeatures
        self.ncorrect = min(max(ncorrect, 0), nfeatures)
        self.maxruns = maxruns
        self.features = []
        self.alpha = alpha
        self.d1 = d1
        self.d2 = d2
        self.temperature = temperature
        self.anticorrelated = anticorrelated
        self.build_features()
        
    def build_features(self):
        n = self.nfeatures
        a = self.alpha
        d1 = self.d1
        d2 = self.d2
        t = self.temperature
        ac = self.anticorrelated
        
        self.features = [Feature(a, d1, d2, t, ac) for i in range(n)]
    
    @property
    def alpha(self):
        return self._alpha
    
    @alpha.setter
    def alpha(self, val):
        self._alpha = val
        for f in self.features:
            f.alpha = val
    
    @property
    def d1(self):
        return self._d1
    
    @d1.setter
    def d1(self, val):
        self._d1 = val
        for f in self.features:
            f.d1 = val
            
    @property
    def d2(self):
        return self._d2
    
    @d2.setter
    def d2(self, val):
        self._d2 = val
        for f in self.features:
            f.d2 = val
            
    @property
    def temperature(self):
        return self._temperature
    
    @temperature.setter
    def temperature(self, val):
        self._temperature = val
        for f in self.features:
            f.temperature = val

    def generate_target(self):
        target = [0 for f in self.features]
        indices = list(range(self.nfeatures))
        random.shuffle(indices)
        for j in indices[0 : self.ncorrect]:
            target[j] = 1
        return target
        
    def select_features(self):
        for f in self.features:
            f.select()
        return [x.selected_binary for x in self.features]
    
    def update(self, rt):
        for f in self.features:
            f.update(rt)
    
    def simulate(self):
        T = self.generate_target()
        O = self.select_features()
        j = 0
        
        while j < self.maxruns and T != O:
            self.update(-1)
            O = self.select_features()
            j += 1
            
        return j