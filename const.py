import math
import array

# All of this could be condensed into one function theoretically, but conditionals would incresase runtime
def hash_const512() :
    primes = sieve(20)
    ret = array.array('d', [])
    current
    for i in range(1, primes.length) :
        current = math.sqrt(primes[i])
        ret.append(double(int(current) - current))
    return ret

def hash_const256() :
    primes = sieve(20)
    ret = array.array('f', [])
    current
    for i in range(1, primes.length) :
        current = math.sqrt(primes[i])
        ret.append(float(int(current) - current))
    return ret

def round_const512() :
    primes = sieve(312)
    ret = array.array('d', [])
    current
    for i in range(1, primes.length) :
        current = primes[i] ** (1/3)
        ret.append(double(int(current) - current))
    return ret

def round_const256() :
    primes = sieve(312)
    ret = array.array('f', [])
    current
    for i in range(1, primes.length) :
        current = primes[i] ** (1/3)
        ret.append(float(int(current) - current))
    return ret

# Sieve of Eratosthenes, for finding prime numbers under some max
def sieve(max: int) :
    arr_check = [true] * (max - 1)
    up_bound = math.sqrt(max - 1)
    for i in range(1, up_bound):
        if arr_check[i]:
            j = i * i
            n = 0
            while (j < max - 1)
                  arr_check[j] = false
                  j + n * i
                  n++
    arr_ret = [2]
    for i in range(3, max - 1):
        if arr_check[i]
            arr_ret.append(i)
    return arr_ret
