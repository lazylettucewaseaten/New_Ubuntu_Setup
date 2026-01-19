#include <bits/stdc++.h>
using namespace std;

using int64 = long long;
using i128 = __int128_t;

/* ---------- GLOBALS ---------- */
mt19937_64 rng(chrono::steady_clock::now().time_since_epoch().count());
const int MAXP = 1000000;
vector<int> small_primes;

/* ---------- SMALL PRIME SIEVE ---------- */
void sieve() {
    vector<bool> is_prime(MAXP + 1, true);
    is_prime[0] = is_prime[1] = false;
    for (int i = 2; i <= MAXP; i++) {
        if (is_prime[i]) {
            small_primes.push_back(i);
            if ((int64)i * i <= MAXP)
                for (int j = i * i; j <= MAXP; j += i)
                    is_prime[j] = false;
        }
    }
}

/* ---------- MOD MUL ---------- */
int64 mulmod(int64 a, int64 b, int64 mod) {
    return (i128)a * b % mod;
}

/* ---------- MOD POW ---------- */
int64 powmod(int64 a, int64 d, int64 mod) {
    int64 res = 1;
    while (d) {
        if (d & 1) res = mulmod(res, a, mod);
        a = mulmod(a, a, mod);
        d >>= 1;
    }
    return res;
}

/* ---------- MILLER RABIN ---------- */
bool isPrime(int64 n) {
    if (n < 2) return false;
    for (int64 p : {2,3,5,7,11,13,17,19,23,29,31,37}) {
        if (n == p) return true;
        if (n % p == 0 && n != p) return false;
    }

    int64 d = n - 1, s = 0;
    while ((d & 1) == 0) d >>= 1, s++;

    for (int64 a : {2,325,9375,28178,450775,9780504,1795265022}) {
        if (a % n == 0) continue;
        int64 x = powmod(a, d, n);
        if (x == 1 || x == n - 1) continue;

        bool composite = true;
        for (int i = 0; i < s - 1; i++) {
            x = mulmod(x, x, n);
            if (x == n - 1) {
                composite = false;
                break;
            }
        }
        if (composite) return false;
    }
    return true;
}

/* ---------- POLLARD RHO ---------- */
int64 pollard(int64 n) {
    if (n % 2 == 0) return 2;
    if (n % 3 == 0) return 3;

    int64 c = uniform_int_distribution<int64>(1, n - 1)(rng);
    int64 x = uniform_int_distribution<int64>(0, n - 1)(rng);
    int64 y = x;
    int64 d = 1;

    auto f = [&](int64 x) {
        return (mulmod(x, x, n) + c) % n;
    };

    while (d == 1) {
        x = f(x);
        y = f(f(y));
        d = __gcd(abs(x - y), n);
    }

    if (d == n) return pollard(n);
    return d;
}

/* ---------- FACTORIZATION ---------- */
void factor(int64 n, vector<int64>& fac) {
    if (n == 1) return;

    if (n <= MAXP) {
        fac.push_back(n);
        return;
    }

    if (isPrime(n)) {
        fac.push_back(n);
        return;
    }

    int64 d = pollard(n);
    factor(d, fac);
    factor(n / d, fac);
}

/* ---------- SUM OF DIVISORS ---------- */
int64 sum_of_divisors(int64 n) {
    int64 ans = 1;

    for (int p : small_primes) {
        if ((int64)p * p > n) break;
        if (n % p == 0) {
            int cnt = 0;
            int64 cur = 1, term = 1;
            while (n % p == 0) {
                n /= p;
                cnt++;
                cur *= p;
                term += cur;
            }
            ans *= term;
        }
    }

    if (n > 1) {
        if (isPrime(n)) {
            ans *= (1 + n);
        } else {
            vector<int64> fac;
            factor(n, fac);
            sort(fac.begin(), fac.end());
            for (int i = 0; i < (int)fac.size(); ) {
                int64 p = fac[i];
                int64 cur = 1, term = 1;
                while (i < (int)fac.size() && fac[i] == p) {
                    i++;
                    cur *= p;
                    term += cur;
                }
                ans *= term;
            }
        }
    }

    return ans;
}


ll ext_gcd(ll a, ll b, ll &x, ll &y) {
    if (b == 0) {
        x = 1;
        y = 0;
        return a;
    }
    ll x1, y1;
    ll g = ext_gcd(b, a % b, x1, y1);
    x = y1;
    y = x1 - (a / b) * y1;
    return g;
}

// Solves a*x + b*y = c
// Returns true if solution exists, and stores one solution in x, y
bool solve_linear_diophantine(ll a, ll b, ll c, ll &x, ll &y) {
    ll x0, y0;
    ll g = ext_gcd(a, b, x0, y0);

    if (c % g != 0)
        return false; // no solution

    ll k = c / g;
    x = x0 * k;
    y = y0 * k;
    return true;
}



/* ---------- MAIN ---------- */
int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    sieve();  // precompute small primes once

    int T;
    cin >> T;
    while (T--) {
      
             
    }
    return 0;
}

